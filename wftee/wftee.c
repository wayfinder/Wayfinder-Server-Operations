/* wftee.c
 *
 * Wayfinder tee with file/log rotation according to a template and 
 * generic failure recovery.
 *
 * Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 *     * Redistributions of source code must retain the above copyright notice,
 *     this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *     * Neither the name of the Vodafone Group Services Ltd nor the names of
 *     its contributors may be used to endorse or promote products derived from
 *     this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <unistd.h>
#include <pthread.h>
#include <string.h>
#include <signal.h>
#include <time.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <libgen.h> // basename()

///////////////////////////////////////// Macros
char time_buf[100];
time_t time_val;

#define TIME_NOW   time_val = time(NULL); strftime(time_buf, 99, "[wf_tee] %Y-%m-%d %H:%M:%S ", localtime(&time_val)); fprintf(stderr, time_buf);
#define DEBUG(...) if (opt_debug) { TIME_NOW; fprintf(stderr, "DEBUG: "); fprintf(stderr, __VA_ARGS__); }
#define INFO(...) if (opt_debug || opt_verbose) { TIME_NOW; fprintf(stderr, "INFO: "); fprintf(stderr, __VA_ARGS__); }
#define WARN(...)  TIME_NOW; fprintf(stderr, "WARN: "); fprintf(stderr, __VA_ARGS__);
#define FATAL(...) TIME_NOW; fprintf(stderr, "FATAL: "); fprintf(stderr, __VA_ARGS__); exit(1);
///////////////////////////////////////// Macros

///////////////////////////////////////// Configurables
#define COMPRESS_CMD        "/usr/bin/bzip2"
#define COMPRESS_NICE_LEVEL 10

#define ROTATE_CHECK_INTERVAL 60
///////////////////////////////////////// Configurables

bool opt_debug = false;
bool opt_verbose = false;
bool opt_compress = false;
bool opt_move = false;
const char* file_template = NULL;
char* cur_filename_complete = NULL;
char* old_filename_complete = NULL;
char* cur_filename = NULL;
char* old_filename = NULL;
char* move_path = NULL;
int outfile = -1;

void compress(const char* filename) {
   int child;

   child = fork();
   if (child < 0)
   {
      WARN("Error when trying to compress, the dark side of the fork has prevailed (%s)\n", strerror(errno));
      return;
   }
   if (child > 0) {
      DEBUG("Parent successfully spawned child\n");
      return;
   }
           
   DEBUG("The fork was with me. exec() of COMPRESS_CMD (%s) with %s arg1 next.\n", COMPRESS_CMD, filename);
   if (execl(COMPRESS_CMD, COMPRESS_CMD, filename, (char *)NULL) < 0) {
      FATAL("compress(): child: execl() of %s failed, error is: %s\n", COMPRESS_CMD, strerror(errno));
   }
}


void usage(const char* argv0)
{
   fprintf(stderr, "Usage:\n");
   fprintf(stderr, "%s [-v] [-d] [-c] [-m path] file_template\n\n", argv0);
   fprintf(stderr, "  -v - turn on verbose mode\n");
   fprintf(stderr, "  -d - turn on debug messages\n");
   fprintf(stderr, "  -c - turn on compression\n");
   fprintf(stderr, "  -m - set directory to move files to after rotation\n\n");
   fprintf(stderr, "file_template is a filename with optional strftime(3) format specifiers\nand is rotated when the expanded name changes. Use double %% characters to include\nthe data but not use it for rotation\n");
   fprintf(stderr, "  example: log_file_%%Y%%m%%d.txt will name the log file according to todays\n");
   fprintf(stderr, "  date, e.g. log_file_20100615.txt, and automatically rotate it every day,\n");
   fprintf(stderr, "  the next file name would be log_file_20100616.txt\n");
   fprintf(stderr, "  Too also include the hour and minute in the file name but still rotate\n");
   fprintf(stderr, "  when the date changes use log_file_%%Y%%m%%d%%%%H%%%%M.txt\n");
}

void parse_cmdline(int argc, char* const argv[])
{
   int c;
   extern char *optarg;
   extern int optind, optopt, opterr;

   while ((c = getopt(argc, argv, "vdcm:")) != -1) {
      switch(c) {
         case 'v':
            opt_verbose = true;
            break;
         case 'c':
            opt_compress = true;
            break;
         case 'd':
            opt_debug = true;
            break;
         case 'm':
            opt_move = true;
            move_path = strdup(optarg);
            break;
         case '?':
            fprintf(stderr, "Unknown command line option %c\n", (char)optopt);
            usage(argv[0]);
            exit(1);
            break;
      }
  }
  if (optind < argc) {
     file_template = argv[optind++];
  } else {
     fprintf(stderr, "No file_template argument!\n");
     usage(argv[0]);
     exit(1);
  }
  if (optind < argc) {
     fprintf(stderr, "You must also specify a file_template argument!\n");
     usage(argv[0]);
     exit(1);
  }
  DEBUG("parse_cmdline() done:\n");
  DEBUG("parse_cmdline() verbose: %d\n", opt_verbose);
  DEBUG("parse_cmdline() debug: %d\n", opt_debug);
  DEBUG("parse_cmdline() compress: %d\n", opt_compress);
  DEBUG("parse_cmdline() move: %d, path: %s\n", opt_move, move_path);
}

void open_or_rotate_file()
{
   char time_buf[strlen(file_template) + 100];
   time_t time_val;

   if (outfile > 0) {
      // close already open file
      if (close(outfile) < 0) {
          WARN("open_or_rotate_file(): Problem closing old file when rotating, error: %s\n", strerror(errno));
          if (errno == EINTR) {
             // try once more
             if(close(outfile) < 0)
                return;
          } else
            return;
      }
   }

   DEBUG("open_or_rotate_file(): #1 old_filename: %s, old_filename_complete: %s, cur_filename: %s, cur_filename_complete: %s\n", 
         old_filename, old_filename_complete, cur_filename, cur_filename_complete);
   if (old_filename != NULL) {
      free(old_filename);
   }
   old_filename = cur_filename;
   if (old_filename_complete != NULL) {
      free(old_filename_complete);
   }
   old_filename_complete = cur_filename_complete;
   time_val = time(NULL); 
   strftime(time_buf, sizeof(time_buf), file_template, localtime(&time_val));
   cur_filename = strdup(time_buf);
   strftime(time_buf, sizeof(time_buf), cur_filename, localtime(&time_val));
   cur_filename_complete = strdup(time_buf);
   DEBUG("open_or_rotate_file(): #2 old_filename: %s, old_filename_complete: %s, cur_filename: %s, cur_filename_complete: %s\n", 
         old_filename, old_filename_complete, cur_filename, cur_filename_complete);

   outfile = open(cur_filename_complete, O_WRONLY | O_CREAT | O_TRUNC, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);
   if (outfile < 0) {
      FATAL("Error opening file %s: %s", cur_filename_complete, strerror(errno));
   }
   DEBUG("open_or_rotate_file(): end of function\n");
}

void check_and_do_file_rotation(int signal)
{
   char* old_filename = strdup(cur_filename_complete);
   bool rotated = false;
   char time_buf[strlen(file_template) + 100];
   time_t time_val;
 
   DEBUG("check_and_do_file_rotation: ALARM!\n");
   // check if we should rotate and call rotate function
   time_val = time(NULL); 
   strftime(time_buf, sizeof(time_buf), file_template, localtime(&time_val));
   if (strcmp(time_buf, cur_filename) != 0) {
      DEBUG("check_and_do_file_rotation(): doing forced rotation\n");
      open_or_rotate_file();
      rotated = true;
   }

   // Did we rotate?
   if (rotated) {
      DEBUG("check_and_do_file_rotation(): file has been rotated\n");
      if (opt_move) {
         char* moved_filename = NULL;
         char* temp = NULL;
         char* basep = NULL;
         char* base = NULL;
         DEBUG("check_and_do_file_rotation(): moving file\n");
         temp = strdup(old_filename);
         basep = basename(temp); // basename can mess with temp and return a pointer within temp
         base = strdup(basep);
         free(temp);
         DEBUG("check_and_do_file_rotation(): base: %s\n", base);
         // base is now a copy of the base filename
         moved_filename = malloc(strlen(base) + strlen(move_path) + 2); // some extra space for \0 and '/'
         strcpy(moved_filename, move_path);
         strcat(moved_filename, "/");
         strcat(moved_filename, base);
         DEBUG("check_and_do_file_rotation(): moved filename: %s\n", moved_filename);
         free(base);
         INFO("check_and_do_file_rotation(): moving file %s to %s\n", old_filename, moved_filename);
         if (rename(old_filename, moved_filename) < 0) {
            WARN("Could not move file %s to path %s (%s), reason: %s\n", old_filename, moved_filename, move_path, strerror(errno));
            free(moved_filename);
         } else {
            DEBUG("check_and_do_file_rotation(): move was successful\n");
            // set old_filename to moved_filename
            free(old_filename);
            old_filename = moved_filename;
         }
      }
      if (opt_compress) {
         INFO("check_and_do_file_rotation(): compressing file %s\n", old_filename);
         compress(old_filename);
      }
      DEBUG("check_and_do_file_rotation(): rotate handling done\n");
   }
   free(old_filename);
   DEBUG("check_and_do_file_rotation: setting alarm\n");
   alarm(ROTATE_CHECK_INTERVAL);
}

int select_and_write(int fd, const void *buf, int size)
{
   // check if it's writeable with a very small timeout, if not don't write and return -1
   fd_set write_fds;
   struct timeval tv;

   FD_ZERO(&write_fds);
   FD_SET(fd, &write_fds);
   memset(&tv, 0, sizeof(struct timeval));
   tv.tv_usec = 10000; // 10 ms
   if (select(fd + 1, NULL, &write_fds, NULL, &tv) > 0 && FD_ISSET(fd, &write_fds)) {
/*   DEBUG("select_and_write: OK to write, writing size: %d data", size); */
      return write(fd, buf, size);
   }
   return -1;
}

void do_tee()
{
   bool teeing = true;
   char buf[16384];
   int read_bytes, written_bytes;
   signal(SIGALRM, check_and_do_file_rotation);
   open_or_rotate_file();
   DEBUG("do_tee: setting alarm\n");
   alarm(ROTATE_CHECK_INTERVAL);
   while (teeing) {
      read_bytes = read(0, buf, sizeof(buf));
      if (read_bytes > 0) {
         select_and_write(1, &buf, read_bytes);  // stdout
         written_bytes = select_and_write(outfile, &buf, read_bytes);
         if (written_bytes != read_bytes) {
            // write error on output file, ignored to handle temporary failures
            WARN("Error writing to output file!\n");
         }
      } else {
         if (errno != EINTR) { // EINTR is ignored
            // Can't read from stdin any longer, time to exit 
            teeing = false;
            if (read_bytes == -1) {
               close(outfile);
               FATAL("Error reading from stdin: %s", strerror(errno));
            }
         }
      }
   }
   close(outfile);
   DEBUG("do_tee: returning...\n");
}

int main(int argc, char* argv[]) 
{
   parse_cmdline(argc, argv);
   do_tee();
   DEBUG("Exiting main.\n");
   return(0);
}
