#!/usr/bin/perl -w

# Handle Supervisor data 
#
# Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice,
#     this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#     * Neither the name of the Vodafone Group Services Ltd nor the names of
#     its contributors may be used to endorse or promote products derived from
#     this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

package MC2SupervisorHelper;

use strict;
use Data::Dumper;
use File::Basename;
use FindBin;
use lib $FindBin::Bin;

use vars qw(@ISA @EXPORT @EXPORT_OK);
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
   start_supervisor get_data_from_supervisor parse_supervisor_data
   create_average_hash_per_moduletype
   $debug
);

my $debug = 1;

sub start_supervisor
{
   my $supervisor_binary = "./Supervisor"; # Naive default
   if ( ! -e $supervisor_binary) {
      # try to find the newest one in /mc2/bin-x.xx.xx/
      $supervisor_binary =`ls -tr /mc2/*/Supervisor | tail -1`;
      chomp($supervisor_binary);
   }
   -e $supervisor_binary || die "FATAL: Can't find a Supervisor";

   $debug && print STDERR "DEBUG: Going to use Supervisor: $supervisor_binary\n";
   chdir(dirname($supervisor_binary));
   my $supervisor_file;
   my $supervisor_pid = open ($supervisor_file, "$supervisor_binary --stabilize --raw 2>/dev/null|") || die "Can't start $supervisor_binary";
   sleep 1;
   $debug && print STDERR "DEBUG: Supervisor pid: $supervisor_pid\n";
   return ($supervisor_file, $supervisor_pid);
}

sub get_data_from_supervisor
{
   my ($supervisor, $supervisor_pid, $time_to_read) = @_;
   my $end_at = time + $time_to_read;
   $debug && print STDERR "DEBUG: get_data_from_supervisor(): will read until $end_at, time is now: " . time . "\n";
   my %data;
   READ_DATA: while (time <= $end_at) {
      my $input = <$supervisor>;
      chomp $input;
      next READ_DATA if ($input =~ m/^Supervisor|^$/);
      my $unique_part = $input;
      $unique_part =~ s/(^[^:]+:[^:]+:[^:]+):.*/$1/;
      $data{$unique_part} = $input;
   }
   $debug && print STDERR "DEBUG: get_data_from_supervisor(): finished reading\n";
   kill 15, $supervisor_pid;
   $debug && print STDERR "DEBUG: get_data_from_supervisor(): kill 15\n";
   kill 9, $supervisor_pid;
   $debug && print STDERR "DEBUG: get_data_from_supervisor(): kill 9\n";
   close $supervisor;
   $debug && print STDERR "DEBUG: get_data_from_supervisor(): closed\n";
   return \%data;
}

sub parse_supervisor_data
{
   my $data = shift;
   my %status = ();
#   $debug && print STDERR "DEBUG: parse_supervisor_data() doing nothing so far, but here's the data, " . scalar keys (%$data) . " lines in total.\n";
#   print STDERR Data::Dumper->Dump([$data],['*data']);
  # n11:8005:SM1 :mc2:  0/S:1:0.00:0.01:0.02:96:(100001b 100002e 100003b 100004a 1000062 100006c 10000a4 10000cb 10000da 10000ea 10000ef 10000fe 1000105 1000123 100013a 1000144 81000008 8100000c 81000048 81000068 )

   foreach my $key (keys %$data) {
      $_ = $data->{$key};
      my ($node, $port, $module_type_raw, $user, $module_queue_status_raw, $process_time, $load_one, $load_five, $load_fifteen, $mem_used, $map_list_raw ) = split /:/;
      my ($module_queue_length, $module_queue_status) = split /\//, $module_queue_status_raw;
      my $module_leader = 0;
      my $module_mapset = 0;
      # extract leader info
      if ($module_type_raw =~ m/\*/) {
         $module_leader = 1;
         $module_type_raw =~ s/\*//;
      }
      # extract module type and mapset info
      my $module_type = $module_type_raw;
      if ($module_type =~ m/\d/) {
         $module_type =~ s/(\d+)//;
         $module_mapset = $1;
      }
      my $map_list = $map_list_raw;
      $map_list =~ s/[()]//g;
      # remove whitespace we don't want
      $module_type =~ s/ //g;
      $status{"$node-$module_type$module_mapset-$port"} = {
         'node'         => $node,
         'port'         => $port,
         'type'         => $module_type,
         'is_leader'    => $module_leader,
         'mapset'       => $module_mapset,
         'queue_length' => $module_queue_length,
         'queue_status' => $module_queue_status,
         'process_time' => $process_time,
         'load_one'     => $load_one,
         'load_five'    => $load_five,
         'load_fifteen' => $load_fifteen,
         'mem_used'     => $mem_used,
         'map_list'     => $map_list,
      };
   }
   $debug > 2 && print STDERR "DEBUG: parsed: " . Data::Dumper->Dump([\%status],['*status']);
   return \%status;
}

sub create_average_hash_per_moduletype
{
   my ($status, $values) = @_;
   my %averages;
   my %temp_totals;
   my %temp_count;
   foreach my $id (keys %$values) {
      my $module_type_mapset = $status->{$id}->{'type'} . $status->{$id}->{'mapset'};
      $temp_totals{$module_type_mapset} += $values->{$id};
      $temp_count{$module_type_mapset} ++;
   }
   foreach my $mod_type (keys %temp_totals) {
      $averages{$mod_type} = sprintf("%.2f", $temp_totals{$mod_type} / $temp_count{$mod_type});
   }
   return \%averages;
}

1;
