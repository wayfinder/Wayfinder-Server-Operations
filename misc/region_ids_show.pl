#!/usr/bin/perl
# Simple CGI to visualize contents of region_ids.xml
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

use strict;
use CGI qw/:standard/;
use XML::LibXML;

my $debug = 0;

sub xml_get_child_by_name {
   my $node = shift;
   my $node_name = shift;
   foreach my $child ($node->childNodes()) {
      if($child->nodeName eq $node_name) {
         return $child;
      }
   }
   return undef;
}

sub xml_get_attrib_value_by_name {
   my $node = shift;
   my $attrib_name = shift;
   foreach my $attrib ($node->attributes()) {
      if($attrib->nodeName eq $attrib_name) {
         return $attrib->value;
      }
   }
   return undef;
}

sub load_and_parse
{
   my $file = shift;
   if (!  open(FILE, "<$file")) {
      print "Content-type: text/plain\n\nCan't open file $file";
      exit;
   }
   my $xml_input = join " ", <FILE>;
   close(FILE);
   # get rid of white space
   $xml_input =~ s/[\t\n\r]//g;
   $xml_input =~ s/> +</></g;
   my $parser = XML::LibXML->new();
   $parser->load_ext_dtd(0);
   $parser->validation(0);
   # can't get rid of DTD parsing, so I remove the DOCTYPE:
   $xml_input =~ s/<!DOCTYPE[^>]*>//g;
   my $doc = $parser->parse_string($xml_input);

   # First we handle the list of the regions
   my %region_groups = ();
   foreach my $group ($doc->find("/map_generation-mc2/region_group_list/region_group")->get_nodelist) {
      my $ident = xml_get_attrib_value_by_name($group, 'ident');
      $ident =~ s/&/&amp;/g;
      my $id = xml_get_attrib_value_by_name($group, 'id');
      $debug && print STDERR localtime() . " DEBUG: group id: $id, ident: $ident\n";
      $region_groups{$id}->{'ident'} = $ident;
      $region_groups{$id}->{'members'} = [];
   }

   # Then the region data itself
   my %regions = ();
   foreach my $region ($doc->find("/map_generation-mc2/region_ids/region")->get_nodelist) {
      my $ident = xml_get_attrib_value_by_name($region, 'ident');
      $ident =~ s/&/&amp;/g;
      $ident =~ s/_/ /g;
      $ident = ucfirst($ident);
      my $id = xml_get_attrib_value_by_name($region, 'id');
      # There should only region_group_id nodes in here
      $regions{$id}{'ident'} = $ident;
      foreach my $region_group_id_node ($region->childNodes) {
         my $region_group_id = xml_get_attrib_value_by_name($region_group_id_node, 'id');
         push(@{$region_groups{$region_group_id}->{'members'}}, $id);
         push(@{$regions{$id}->{'part_of'}}, $region_group_id);
         $debug && print STDERR localtime() . " DEBUG: region id: $id, ident: $ident, member of $region_group_id\n";
      }
   }
   return (\%region_groups, \%regions);
}

sub display_as_html
{
   my $region_groups = shift;
   my $regions = shift;
   my $region_file = shift;

#   print header('text/html') . "\n";
   print "Content-Type: text/html\n\n";
   print start_html({title=>"Region IDs", BGCOLOR=>'#FFFFFF'}) . "\n";
   print h1("Region IDs") . "\n";
   print "<p><font size=\"-1\">Data from: $region_file</font></p>\n";
   print "<a href=\"#region_groups\">Region groups</a><br>\n";
   print "<a href=\"#regions\">Regions</a>\n";
   print "<a name=\"region_groups\"></a>\n";
   print h2("Region groups") . "<ul>\n";
   foreach my $region_group_id (sort { $region_groups->{$a}->{'ident'} cmp $region_groups->{$b}->{'ident'} } keys %$region_groups) {
      print "<li>" . $region_groups->{$region_group_id}->{'ident'} . " ($region_group_id)";
      if (@{$region_groups->{$region_group_id}->{'members'}}) {
         print "\n<ul><li> <i>Members: </i>\n";
         foreach my $region_group_member_id (sort { $regions->{$a}->{'ident'} cmp $regions->{$b}->{'ident'} } @{$region_groups->{$region_group_id}->{'members'}}) {
             print $regions->{$region_group_member_id}->{'ident'} . ", ";
         }
         print "\n</ul>\n";
      }
      print "\n";
   }
   print "</ul>\n" ;
   print "<a name=\"regions\"></a>\n";
   print h2("Regions") . "<ul>\n";
   
   foreach my $region_id (sort { $regions->{$a}->{'ident'} cmp $regions->{$b}->{'ident'} } keys %$regions) {
      print "<li>" . $regions->{$region_id}->{'ident'} . " ($region_id)";
      if (defined($regions->{$region_id}->{'part_of'}) && @{$regions->{$region_id}->{'part_of'}}) {
         print "\n<ul><li> <i>Part of: </i>\n";
         foreach my $region_group_id (sort { $region_groups->{$a}->{'ident'} cmp $region_groups->{$b}->{'ident'} } @{$regions->{$region_id}->{'part_of'}}) {
             print $region_groups->{$region_group_id}->{'ident'} . ", ";
         }
         print "\n</ul>\n";
      }
      print "\n";
   }
   print "</ul>\n";
   print end_html ."\n";
}
my $region_file = "./region_ids.xml";
if ( ! -e $region_file) {
   # try to find the newest one in /mc2/bin-x.xx.xx/
   $region_file =`ls -tr /mc2/*/region_ids.xml | tail -1`;
   chomp($region_file);
}
if (! -e $region_file) {
   print "Content-Type: text/plain\n\nCan't find any region_ids.xml file ($region_file)";
   exit;
}

my ($region_groups, $regions) =  load_and_parse($region_file);
display_as_html($region_groups, $regions, $region_file);

