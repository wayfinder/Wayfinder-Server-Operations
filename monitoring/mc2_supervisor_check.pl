#!/usr/bin/perl -w
# Check that an mc2 instance is doing alright.
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
#
use strict;
use Data::Dumper;
use File::Basename;
use FindBin;
use lib $FindBin::Bin;
use MC2SupervisorHelper;

$debug = 1;

die "Need to know which config to use!" if (scalar @ARGV < 1);
our %limits = ();
require "mc2_supervisor_check_" . $ARGV[0] . "_conf.pl";

# helper for check_parsed_data
sub check_one_limit_using_status_for_limit_id
{
   my ($status, $values, $limits, $value_name) = @_;
   foreach my $id (keys %$values) {
      my $module_type_mapset = $status->{$id}->{'type'} . $status->{$id}->{'mapset'};
      my $limit = $limits->{$value_name}->{ $module_type_mapset };
      if (defined($limit)) {
         if (eval ($values->{$id} . $limit)) {
            print STDERR "ALERT: $id has $value_name: " . $values->{$id} .  " (limit is $limit)\n";
         }
      } else {
         print STDERR "ALERT: No limit for $value_name found for $id ($module_type_mapset)\n";
      }
   }
}

# helper for check_parsed_data
sub check_one_limit_hash_key_is_limit_id
{
   my ($values, $limits, $value_name) = @_;
   foreach my $id (keys %$values) {
      my $limit = $limits->{$value_name}->{ $id };
      if (defined($limit)) {
         if (eval ($values->{$id} . $limit)) {
            print STDERR "ALERT: $id has $value_name: " . $values->{$id} .  " (limit is $limit)\n";
         }
      } else {
         print STDERR "ALERT: No limit for $value_name found for $id\n";
      }
   }
}

sub check_parsed_data
{
   my ($status, $limits) = @_;
   $debug && print STDERR "DEBUG: check_parsed_data() top, checking leader and module counts\n";
   # Check that all types have one leader
   my %leaders;
   foreach my $key (keys %$status) {
      my ($type, $mapset, $is_leader) =  @{$status->{$key}}{'type', 'mapset', 'is_leader'};
      $leaders{$type . $mapset} += $is_leader;
   }
   $debug > 2 && print STDERR "DEBUG: Leader data: " . Data::Dumper->Dump([\%leaders],['*leaders']);
   check_one_limit_hash_key_is_limit_id(\%leaders, $limits, 'leaders');
   # Check for minimum counts of modules per module type
   my %module_count;
   foreach my $key (keys %$status) {
      my ($type, $mapset) =  @{$status->{$key}}{'type', 'mapset'};
      $module_count{$type . $mapset}++;
   }
   $debug > 2 && print STDERR "DEBUG: Module count: " . Data::Dumper->Dump([\%module_count],['*module_count']);
   check_one_limit_hash_key_is_limit_id(\%module_count, $limits, 'module_count');
   $debug && print STDERR "DEBUG: check_parsed_data() top, checking individual queue length, load and process time\n";
   # Check individual queue length, load and process time
   my %module_queue_length;
   my %module_load_one;
   my %module_load_five;
   my %module_load_fifteen;
   my %module_process_time;
   # these hashes are also used later to calculate averages
   foreach my $key (keys %$status) {
      my ($node, $type, $mapset, $port, $queue_length, $process_time, $load_one, $load_five, $load_fifteen) = 
         @{$status->{$key}}{'node', 'type', 'mapset', 'port', 'queue_length', 'process_time', 'load_one', 'load_five', 'load_fifteen'};
      $module_queue_length{$key} = $queue_length;
      $module_load_one{$key}     = $load_one;
      $module_load_five{$key}    = $load_five;
      $module_load_fifteen{$key} = $load_fifteen;
      $module_process_time{$key} = $process_time;
   }
   $debug > 2 && print STDERR "DEBUG: Module queue length: " . Data::Dumper->Dump([\%module_queue_length],['*module_avg_queue_length']);
   $debug > 2 && print STDERR "DEBUG: Module load one: "     . Data::Dumper->Dump([\%module_load_one],    ['*module_avg_load_one']);
   $debug > 2 && print STDERR "DEBUG: Module load five: "    . Data::Dumper->Dump([\%module_load_five],   ['*module_avg_load_five']);
   $debug > 2 && print STDERR "DEBUG: Module load fifteen: " . Data::Dumper->Dump([\%module_load_fifteen],['*module_avg_load_fifteen']);
   $debug > 2 && print STDERR "DEBUG: Module process time: " . Data::Dumper->Dump([\%module_process_time],['*module_avg_process_time']);
   check_one_limit_using_status_for_limit_id($status, \%module_queue_length, $limits, 'queue_length');
   check_one_limit_using_status_for_limit_id($status, \%module_load_one,     $limits, 'load_one');
   check_one_limit_using_status_for_limit_id($status, \%module_load_five,    $limits, 'load_five');
   check_one_limit_using_status_for_limit_id($status, \%module_load_fifteen, $limits, 'load_fifteen');
   check_one_limit_using_status_for_limit_id($status, \%module_process_time, $limits, 'process_time');
   $debug && print STDERR "DEBUG: check_parsed_data() top, checking average queue length, load and process time\n";
   # Check average queue length, load and process time
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
   check_one_limit_hash_key_is_limit_id($module_avg_queue_length, $limits, 'avg_queue_length');
   check_one_limit_hash_key_is_limit_id($module_avg_load_one,     $limits, 'avg_load_one');
   check_one_limit_hash_key_is_limit_id($module_avg_load_five,    $limits, 'avg_load_five');
   check_one_limit_hash_key_is_limit_id($module_avg_load_fifteen, $limits, 'avg_load_fifteen');
   check_one_limit_hash_key_is_limit_id($module_avg_process_time, $limits, 'avg_process_time');
}

my ($supervisor, $supervisor_pid) = start_supervisor();
# the stabilize option delays output for 4 seconds, so we'll read for 5 
# (ran it about 100 times with 5 and it never failed)
my $supervisor_data = get_data_from_supervisor($supervisor, $supervisor_pid, 5);
my $mc2_status = parse_supervisor_data($supervisor_data); 
check_parsed_data($mc2_status, \%limits);
