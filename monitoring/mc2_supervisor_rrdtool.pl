#!/usr/bin/perl -w # Check that an mc2 instance is doing alright.
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

use strict;
use Data::Dumper;
use File::Basename;
use FindBin;
use lib $FindBin::Bin;
use RRDs;
use MC2SupervisorHelper;

$debug = 4;
die "Need to know which config to use!" if (scalar @ARGV < 1);
our %config = ();
my $config_name = $ARGV[0];
require "mc2_supervisor_rrdtool_$config_name" . "_conf.pl";
$debug && print STDERR "DEBUG: Config: " . Data::Dumper->Dump([\%config],['*config']);

sub create_rrd_if_necessary
{
   my $rrd_name = shift;
   # supports only a single DS right now
   my $ds_name = shift;
   my $rrd_file = $config{'rrd_path'} . "$rrd_name.rrd";
   return 1 if ( -e $rrd_file);
   # 600 samples of 5 minutes  (2 days and 2 hours)
   # 700 samples of 30 minutes (2 days and 2 hours, plus 12.5 days)
   # 775 samples of 2 hours    (above + 50 days)
   # 797 samples of 1 day      (above + 732 days, rounded up to 797)
   # above inspired by RRD tutorial, which was inspired by MRTG
   # uses default step size, 300 seconds
   $debug && print STDERR "DEBUG: create_rrd_if_necessary() about to create RRD $rrd_file with DS $ds_name\n";
   RRDs::create ( $rrd_file, "DS:$ds_name:GAUGE:600:U:U",
      "RRA:AVERAGE:0.5:1:600", "RRA:AVERAGE:0.5:6:700",
      "RRA:AVERAGE:0.5:24:775", "RRA:AVERAGE:0.5:288:797",
      "RRA:MAX:0.5:1:600", "RRA:MAX:0.5:6:700",
      "RRA:MAX:0.5:24:775", "RRA:MAX:0.5:288:797"
   );
   die "ERROR: couldn't create RRD $rrd_file: " . RRDs::error() if RRDs::error();
   return 1;
}

sub update_rrd
{
   my $rrd_name = shift;
   # supports only a single DS right now
   my $ds_value = shift;
   my $rrd_file = $config{'rrd_path'} . "$rrd_name.rrd";
   $debug > 1 && print STDERR "DEBUG: update_rrd(): updating $rrd_file with value: $ds_value\n";
   RRDs::update( $rrd_file, "N:$ds_value");
   die "ERROR: couldn't update $rrd_name.rrd: " . RRDs::error() if RRDs::error();
}

sub update_rrds
{
   my ($status, $limits) = @_;
   $debug && print STDERR "DEBUG: update_rrds() module counts\n";
   # Calculate module counts
   my %module_count;
   foreach my $key (keys %$status) {
      my ($type, $mapset) =  @{$status->{$key}}{'type', 'mapset'};
      $module_count{$type . $mapset}++;
   }
   $debug > 2 && print STDERR "DEBUG: Module count: " . Data::Dumper->Dump([\%module_count],['*module_count']);
   foreach my $module_type (keys %module_count) {
      my $rrd_name = "$config_name-modcount-$module_type";
      create_rrd_if_necessary($rrd_name, "mc-$module_type");
      update_rrd($rrd_name, $module_count{$module_type});
   }
   $debug && print STDERR "DEBUG: update_rrds(), individual queue length, load and process time\n";
   # individual queue length, load and process time
   my %module_queue_length;
   my %module_load_one;
   my %module_load_five;
   my %module_load_fifteen;
   my %module_process_time;
   # the hashes are used later to calculate averages
   foreach my $key (keys %$status) {
      my ($node, $type, $port, $mapset, $queue_length, $process_time, $load_one, $load_five, $load_fifteen) = 
         @{$status->{$key}}{'node', 'type', 'port', 'mapset', 'queue_length', 'process_time', 'load_one', 'load_five', 'load_fifteen'};
      $module_queue_length{$key} = $queue_length;
      $module_load_one{$key}     = $load_one;
      $module_load_five{$key}    = $load_five;
      $module_load_fifteen{$key} = $load_fifteen;
      $module_process_time{$key} = $process_time;
      my $rrd_name = "$config_name-individual-$node-$type$mapset-$port";
      create_rrd_if_necessary($rrd_name . '-queue_length', "ql-$type$mapset");
      update_rrd             ($rrd_name . '-queue_length', $queue_length);
      create_rrd_if_necessary($rrd_name . '-load_one',     "l1-$type$mapset");
      update_rrd             ($rrd_name . '-load_one',     $load_one);
      create_rrd_if_necessary($rrd_name . '-load_five',    "l5-$type$mapset");
      update_rrd             ($rrd_name . '-load_five',    $load_five);
      create_rrd_if_necessary($rrd_name . '-load_fifteen', "l15-$type$mapset");
      update_rrd             ($rrd_name . '-load_fifteen', $load_fifteen);
      create_rrd_if_necessary($rrd_name . '-process_time', "pt-$type$mapset");
      update_rrd             ($rrd_name . '-process_time', $process_time);
   }
   $debug > 2 && print STDERR "DEBUG: Module queue length: " . Data::Dumper->Dump([\%module_queue_length],['*module_queue_length']);
   $debug > 2 && print STDERR "DEBUG: Module load one: "     . Data::Dumper->Dump([\%module_load_one],    ['*module_load_one']);
   $debug > 2 && print STDERR "DEBUG: Module load five: "    . Data::Dumper->Dump([\%module_load_five],   ['*module_load_five']);
   $debug > 2 && print STDERR "DEBUG: Module load fifteen: " . Data::Dumper->Dump([\%module_load_fifteen],['*module_load_fifteen']);
   $debug > 2 && print STDERR "DEBUG: Module process time: " . Data::Dumper->Dump([\%module_process_time],['*module_process_time']);
   # average queue length, load and process time
   $debug && print STDERR "DEBUG: update_rrds(), average queue length, load and process time\n";
   my $module_avg_queue_length = create_average_hash_per_moduletype($status, \%module_queue_length);
   my $module_avg_load_one     = create_average_hash_per_moduletype($status, \%module_load_one);
   my $module_avg_load_five    = create_average_hash_per_moduletype($status, \%module_load_five);
   my $module_avg_load_fifteen = create_average_hash_per_moduletype($status, \%module_load_fifteen);
   my $module_avg_process_time = create_average_hash_per_moduletype($status, \%module_process_time);
   $debug > 2 && print STDERR "DEBUG: Module avg queue length: " . Data::Dumper->Dump([$module_avg_queue_length],['*module_avg_queue_length']);
   $debug > 2 && print STDERR "DEBUG: Module avg load one: "     . Data::Dumper->Dump([$module_avg_load_one],    ['*module_avg_load_one']);
   $debug > 2 && print STDERR "DEBUG: Module avg load five: "    . Data::Dumper->Dump([$module_avg_load_five],   ['*module_avg_load_five']);
   $debug > 2 && print STDERR "DEBUG: Module avg load fifteen: " . Data::Dumper->Dump([$module_avg_load_fifteen],['*module_avg_load_fifteen']);
   $debug > 2 && print STDERR "DEBUG: Module avg process time: " . Data::Dumper->Dump([$module_avg_process_time],['*module_avg_process_time']);
   foreach my $module_type (keys %$module_avg_queue_length) {
      my $rrd_name = "$config_name-average-$module_type-queue_length";
      create_rrd_if_necessary($rrd_name, "avg-ql-$module_type");
      update_rrd($rrd_name, $module_avg_queue_length->{$module_type});
   }
   foreach my $module_type (keys %$module_avg_load_one) {
      my $rrd_name = "$config_name-average-$module_type-load_one";
      create_rrd_if_necessary($rrd_name, "avg-l1-$module_type");
      update_rrd($rrd_name, $module_avg_load_one->{$module_type});
   }
   foreach my $module_type (keys %$module_avg_load_five) {
      my $rrd_name = "$config_name-average-$module_type-load_five";
      create_rrd_if_necessary($rrd_name, "avg-l5-$module_type");
      update_rrd($rrd_name, $module_avg_load_five->{$module_type});
   }
   foreach my $module_type (keys %$module_avg_load_fifteen) {
      my $rrd_name = "$config_name-average-$module_type-load_fifteen";
      create_rrd_if_necessary($rrd_name, "avg-l15-$module_type");
      update_rrd($rrd_name, $module_avg_load_fifteen->{$module_type});
   }
   foreach my $module_type (keys %$module_avg_process_time) {
      my $rrd_name = "$config_name-average-$module_type-process_time";
      create_rrd_if_necessary($rrd_name, "avg-pt-$module_type");
      update_rrd($rrd_name, $module_avg_process_time->{$module_type});
   }
}

my ($supervisor, $supervisor_pid) = start_supervisor();
# the stabilize option delays output for 4 seconds, so we'll read for 5 
# (ran it about 100 times with 5 and it never failed)
my $supervisor_data = get_data_from_supervisor($supervisor, $supervisor_pid, 5);
my $mc2_status = parse_supervisor_data($supervisor_data); 
update_rrds($mc2_status);
