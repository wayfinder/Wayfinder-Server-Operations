#!/usr/bin/perl
#
# Simple CGI to visualize contents of navclientsettings.txt
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
use CGI qw/:standard/;
use XML::LibXML;

my $debug = 0;

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

sub load_and_parse_regions
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
   my %regions = ();
   foreach my $group ($doc->find("/map_generation-mc2/region_group_list/region_group")->get_nodelist) {
      my $ident = xml_get_attrib_value_by_name($group, 'ident');
      $ident =~ s/&/&amp;/g;
      my $id = xml_get_attrib_value_by_name($group, 'id');
      $debug && print STDERR localtime() . " DEBUG: group id: $id, ident: $ident\n";
      $regions{$id}->{'ident'} = $ident;
   }

   foreach my $region ($doc->find("/map_generation-mc2/region_ids/region")->get_nodelist) {
      my $ident = xml_get_attrib_value_by_name($region, 'ident');
      $ident =~ s/&/&amp;/g;
      my $id = xml_get_attrib_value_by_name($region, 'id');
      $regions{$id}{'ident'} = $ident;
   }
   return \%regions;
}

# From the book "Mastering Regular Expressions"
sub parse_csv {
   my $text = shift;      # record containing comma-separated values
   my @new  = ();

   # the first part groups the phrase inside the quotes.
   # see explanation of this pattern in MRE
   push(@new, $+) while $text =~ m{"([^\"\\]*(?:\\.[^\"\\]*)*)",? |  ([^,]+),? | ,}gx;
   push(@new, undef) if substr($text, -1,1) eq ',';
   return @new;      # list of values that were comma-separated
}

sub table_headings
{
   return "<tr><th>Type</th><th>Opt</th><th>MoD</th><th>noAutAg</th><th>AgReg</th><th>AgTime</th><th>AgDate</th><th>BlockDate</th><th>NoCreate</th><th>CreateLevel</th><th>CreateRegion</th><th>CreateTime</th><th>CreateExplTime</th><th>CreateTransD</th><th>Model</th><th>ImgExt</th><th>NoNews</th><th>CCList</th><th>Brand</th><th>CatPrefix</th><th>Ver</th><th>LockedVer</th><th>ServerList</th><th>ExtraRights</th><th>Comment</th></tr>";
}

sub display_as_html
{
   my $regions = shift;
   my $region_file = shift;
   my $navclientsettings_file = shift;
#   print header('text/html') . "\n";
   print "Content-Type: text/html\n\n";
   print start_html({title=>"Navclient settings", BGCOLOR=>'#FFFFFF'}) . "\n";
   print h1("Navclient settings") . "\n";
   print "<p><font size=\"-1\">Data from: $region_file and $navclientsettings_file</font></p>\n";
   if (!  open(FILE, "<$navclientsettings_file")) {
      print "Content-type: text/plain\n\nCan't open file $navclientsettings_file";
      exit;
   }
   my $table_open = 0;
   my @bgcolors =  ('#EEEEEE', '#CCCCCC');
   print "<table><tr><td colspan=\"30\">&nbsp;</td></tr>\n";
   NAVLINE: foreach (<FILE>) {
      # comments and other things that should be output as-is
      if (m/^#/ || m/^VersionLock|^WFID|^Product:|^DrawVersion|^NoGoldLifeTime/) {
         if ($table_open) {
            # print "</table>\n";
            $table_open = 0;
         }
         chomp;
#         print "<pre>$_</pre>\n";
         if (length($_) > 120) {  
            $_ = '<i>Line too long, skipped</i>';
         } else {
            s/ /&nbsp;/g;
         }
         print Tr({-bgcolor=>"#FFFFFF"}, td({-colspan=>"30"},"<tt>$_</tt>"));
         next NAVLINE;
      }
      # skip whitespace
      if (m/^[\s]*$/) {
         next NAVLINE;
      }
      # otherwise it's a client type definition
      if (! $table_open) {
         print table_headings();
         $table_open = 1;
      }
      # try to fix the file so it's easier to parse, had really strange problems with the extra rights string getting truncated
      s/,[\s]+/,/g;
      s/[\s]+,/,/g;
      my $comment;
      ($_, $comment) = split '%';
      $comment =~ s/ /&nbsp;/g;
      my @raw_fields = map { s/"//g; $_;} parse_csv($_);
      my @fields = ();
      push @fields, shift @raw_fields; # client type
      push @fields, shift @raw_fields; # client option
      push @fields, shift @raw_fields; # client Matrix-of-Doom
      push @fields, shift @raw_fields; # noAutoAg
      push @fields, $regions->{shift @raw_fields}->{'ident'}; # AgRegion
      my $silverYear = shift @raw_fields;
      my $silverMonth = shift @raw_fields;
      my $silverDay = shift @raw_fields;
      push @fields, "$silverYear&nbsp;Y,&nbsp;$silverMonth&nbsp;M,&nbsp;$silverDay&nbsp;D"; # AgTime
      push @fields, shift @raw_fields; # AgDate
      push @fields, shift @raw_fields; # BlockDate
      push @fields, shift @raw_fields; # NoCreate
      push @fields, shift @raw_fields; # CreateLevel
      push @fields, $regions->{shift @raw_fields}->{'ident'}; # CreateRegion
      my $createYear = shift @raw_fields;
      my $createMonth = shift @raw_fields;
      my $createDay = shift @raw_fields;
      push @fields, "$createYear&nbsp;Y,&nbsp;$createMonth&nbsp;M,&nbsp;$createDay&nbsp;D"; # CreateTime
      push @fields, shift @raw_fields; # CreateExplTime
      push @fields, shift @raw_fields; # CreateTransD
      push @fields, shift @raw_fields; # Model
      push @fields, shift @raw_fields; # ImgExt
      push @fields, shift @raw_fields; # NoNews
      my $CCList = shift @raw_fields;
      $CCList =~ s/ /&nbsp;/g;
      push @fields, $CCList; # CCList
      push @fields, shift @raw_fields; # Brand
      push @fields, shift @raw_fields; # CatPrefix
      push @fields, shift @raw_fields; # Ver
      push @fields, shift @raw_fields; # LockedVer
      push @fields, shift @raw_fields; # ServerList
      push @fields, shift @raw_fields; # ExtraRights
      push @fields, $comment; 
      print Tr({-bgcolor=>$bgcolors[0]}, td([@fields]));
      @bgcolors = reverse @bgcolors;
   }
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
my $navclientsettings_file = "./navclientsettings.txt";
if ( ! -e $navclientsettings_file) {
   # try to find the newest one in /mc2/bin-x.xx.xx/
   $navclientsettings_file =`ls -tr /mc2/*/navclientsettings.txt | tail -1`;
   chomp($navclientsettings_file);
}
if (! -e $navclientsettings_file) {
   print "Content-Type: text/plain\n\nCan't find any navclientsettings.txt file ($navclientsettings_file)";
   exit;
}

my $regions =  load_and_parse_regions($region_file);

display_as_html($regions, $region_file, $navclientsettings_file);

