#!/usr/bin/perl -w

# Generate config files for running MC2 with multiple map sets on production clusters
#
#
# Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#    * Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#    * Neither the name of the Vodafone Group Services Ltd nor the names of its
#    contributors may be used to endorse or promote products derived from this
#    software without specific prior written permission.
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
#
package MC2Conf;

use Data::Dumper;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(create_hosts create_settings debug_print component server module add_path open_and_add_header add_footer_and_close write_one write_all write_many command comment gen_nodes);

$MC2Conf::debug_level = 2;

sub debug_print
{
   my $this_debug_level = shift;
   ($this_debug_level <= $MC2Conf::debug_level) || return;
   print @_;
}

sub command 
{
   my $the_command = shift;
   my $window_name = shift;
   return "screen -t $window_name $the_command\n";
}

sub comment 
{
   my $the_comment = shift;
   return "#$the_comment\n";
}

sub component
{  
   my $component_name = shift;
   my $component_args = shift;
   my $prefix = shift;
   my $logname = shift;
   my $logparam = "";
   if (defined($prefix)) {
      $logparam = "-p $prefix";
   }
   if (defined($logname)) {
      $logparam = "-n $logname";
   }
   return command("./runBin $logparam $component_name $component_args", @_);
}

sub module
{
   return component(@_);
}

sub server
{
   return component(@_);
}

sub add_path
{
   my $path = shift;
   my $file = shift;
   if (!($path =~ m#/$#)) {
      $path .= '/';
   }
   return $path . $file;
}

sub create_hosts
{
   my $instance = shift;
   my @nodes = @_;
   my $file_name = 'mc2control-' . $instance . '.hosts';
   open(HOSTS, ">$file_name") || die "Could not open $file_name\n";
   print "$file_name "; # logging
   foreach my $node (@nodes) {
      print HOSTS "$node\n";
   }
   close HOSTS;
}

sub create_settings
{
   my $instance = shift;
   my $binpath = shift;
   my $file_name = 'mc2control-' . $instance . '.settings';
   open(SETTINGS, ">$file_name") || die "Could not open $file_name\n";
   print "$file_name "; # logging
   print SETTINGS <<EOF
mc2screenprefix=$instance
mc2Dir="/usr/local/mc2"
mc2BinDir=$binpath
sourceMapDir=""
mapDir=""
tmpNewMapDir=""
tmpOldMapDir=""
logDir=/usr/local/mc2/var/log
installDir=""
EOF
;
   close SETTINGS;
}

sub open_and_add_header
{
   my $instance = shift;
   my $log_path = shift;
   my @nodes = @_;
   my %files = ();
   foreach my $node (@nodes) {
      my $file_name = 'mc2control-' . $instance . '.' . $node;
      MC2Conf::debug_print(4, "DEBUG: opening file: $file_name\n");
      my $file;
      open($file, ">$file_name") || die "Could not open $file_name\n";
      print "$file_name "; # logging
      print $file "setenv LOGFILE_PATH $log_path\n";
      print $file command("/bin/zsh", 'zsh');
      $files{$node} = $file;
   }
   return \%files;
}

sub add_footer_and_close
{
   my $files = shift;
   foreach my $node (keys %$files) {
      debug_print(4, "DEBUG: adding footer and closing mc2control file for node: $node\n");
      my $file = $$files{$node};
      print $file 'hardstatus alwayslastline "%w"' . "\n";
      print $file "detach\n";
      close $file;
   }
}

sub write_all
{
   my $files = shift;
   my $string = shift;
   foreach my $node (keys %$files) {
      debug_print(4, "DEBUG: adding (all) string to file for node: $node\n");
      my $file = $$files{$node};
      print $file $string;
   }
   
}

# should perhaps only haveone write that works like write_many? could replace both 'all' and 'one' easily.
sub write_many
{
   my $files = shift;
   my $nodes = shift;
   my $string = shift;
   foreach my $node (@$nodes) {
      debug_print(4, "DEBUG: adding (many) string to file for node: $node\n");
      my $file = $$files{$node};
      print $file $string;
   }
}

sub write_one
{
   my $files = shift;
   my $node = shift;
   my $string = shift;
   debug_print(4, "DEBUG: adding string to file for node: $node\n");
   my $file = $$files{$node};
   print $file $string;
}

sub gen_nodes
{
  my $prefix = shift;
  my @res = ();
  while(defined(my $n = shift)) {
     push @res, "$prefix$n";
  }
  return @res;
}

1;
