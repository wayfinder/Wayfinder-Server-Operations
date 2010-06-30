#!/usr/bin/perl

# Nagios plugin that uses Ganglia data.
#
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

use IO::Socket;
use XML::LibXML;

$debug = 0;

$ganglia_host = 'bob.itinerary.com';
$ganglia_port = '8651';

sub xpath_socket_document
{
   ($remote_host, $port, $xpath) = @_;
   $server = IO::Socket::INET->new("$remote_host:$port");
   defined $server || die "Couldn't contact $remote_host:$port\n";

   my $parser = XML::LibXML->new();
   my $doc = $parser->parse_fh($server);
	
   my $value = $doc->find($xpath)->to_literal;

   if (defined($value) && $value ne '') {
	   $debug && print "Value: '$value'\n";
	   return $value->value();
   } else {
	   $debug && print "Not found!\n";
	   return undef;
   }
}

# xpath vill look something like this:
# //HOST[@NAME="myhost.mydomain.com"]/METRIC[@NAME="fs_free_usr"]/@VAL
$host = $ARGV[0];
$metric = $ARGV[1];
$warn_level = $ARGV[2];
$crit_level = $ARGV[3];
$low_is_good = $ARGV[4];
$xpath = '//HOST[@NAME="' . $host . '"]/METRIC[@NAME="' . $metric . '"]/@VAL';
$debug && print "xpath: '$xpath'\n";

$val = xpath_socket_document($ganglia_host, $ganglia_port, $xpath);

$debug && print "val: $val, warn: $warn_level, crit: $crit_level, low_is_good: $low_is_good\n";

if (defined $val)
{
	if ((!$low_is_good && ($val < $warn_level)) || ($low_is_good && ($val > $warn_level)))
	{
		print "$metric on $host is WARNING (current value: $val)\n";
		exit 1;
	} elsif ((!$low_is_good && ($val < $crit_level)) || ($low_is_good && ($val > $crit_level)))
	{
		print "$metric on $host is CRITICAL (current value: $val)\n";
		exit 2;
	}
} else {
		print "$metric on $host is UNKNOWN\n";
		exit -1;
}

print "$metric on $host is OK (current value: $val)\n";
exit 0;
