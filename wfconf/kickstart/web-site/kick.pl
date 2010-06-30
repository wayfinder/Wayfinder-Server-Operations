#!/usr/bin/perl -w
#
# kickstart generator for Wayfinder
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
use CGI qw/:standard/; use Data::Dumper;

my $ks_config_file = '/kick/kick-config.pl';
my $ks_ethers_file = '/kick/kick-ethers.pl';

sub log_print {
   print STDERR "kick.pl [" . $ENV{'REMOTE_ADDR'} . "][" . localtime() . "]: ";
   print STDERR @_;
   print STDERR "\n";
}

my %ks_configs = ();
my %ks_ethers = ();
my %ks_ethernet_addresses = ();

sub get_config {
   foreach my $config_file ($ks_config_file, $ks_ethers_file) {
      (-e $config_file) || die "Config file: $config_file does not exist\n";
      open(CFG, "$config_file") || die "could not open config file: $config_file";
      my $cont;
      while (<CFG>) {
      $cont .= $_; }
      close(CFG);
      eval $cont;
   }
}

sub get_macs {
# example:
# ENV/HTTP_X_RHN_PROVISIONING_MAC_0:eth1 00:11:43:FD:9B:95
# ENV/HTTP_X_RHN_PROVISIONING_MAC_1:eth0 00:11:43:FD:9B:94
   my $eth = 0;
   while (defined($ENV{'HTTP_X_RHN_PROVISIONING_MAC_' . $eth})) {
      my ($device, $mac) = split(' ', $ENV{'HTTP_X_RHN_PROVISIONING_MAC_' . $eth});
      $ks_ethernet_addresses{$device} = lc $mac;
      $eth++;
   }
}

sub expand_ks_file {
   my ($ks_conf, $node_conf, $ks_file) = @_;
   my $ks_fileh;
   log_print("expand_ks_file, expanding $ks_file");
   open($ks_fileh, $ks_file) || die "could not open $ks_file";
   while (<$ks_fileh>) {
      # check for expansions
      if (m/<(\w+)>/) {
         my $ks_file_to_expand = $ks_conf->{'kicks'} . '-' . $node_conf->{lc $1} . '-' . $1 . '.ks';
         log_print("found expansion, expanding $1 using $ks_file_to_expand");
         expand_ks_file($ks_conf, $node_conf, $ks_file_to_expand);
      } else {
         print $_;
      }
   }
   close($ks_fileh);
}

sub do_ks {
   my $ks_label = param('label');
   if (!defined $ks_label) {
      $ks_label = 'none';
   }
   my $this_config = $ks_configs{$ks_label};

   print "Content-type: text/plain\n\n";

   #foreach my $k (keys %ENV) {
   #    log_print("ENV/$k:$ENV{$k}");
   #}

   foreach my $k (keys %ks_ethernet_addresses) {
       log_print("Device $k: '$ks_ethernet_addresses{$k}'");
   }
   if (defined($this_config)) {
      log_print("config for $ks_label, basedir: " . $this_config->{'basedir'});
      log_print("config for $ks_label, kicks:   " . $this_config->{'kicks'});
      # check ethers
      my $mac = $ks_ethernet_addresses{'eth0'};
      #print "DEBUG: " . Data::Dumper->Dump([\%ks_ethers],['*ks_ethers']);

      # pull default first and then stuff per mac config into it
      # default can't (shouldn't/not intended to) be used alone, that's why we return an error otherwise
      my $node_config = $ks_ethers{'default'};
      my $node_config_mac = $ks_ethers{$mac};
      if (defined $node_config_mac) {
	 my %merged_config = (%$node_config, %$node_config_mac);
         expand_ks_file($this_config, \%merged_config, $this_config->{'kicks'} . '-base.ks');
      } else {
         log_print("No config for this host!");
         die "No config for this host!\n";
      }

   } else {
      log_print("Unknown label: $ks_label");
      die "Unknown label ($ks_label)\n";
   }
}

# main
get_config();
get_macs();
do_ks();
