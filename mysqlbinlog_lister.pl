#!/usr/bin/perl

########################################################################
# Copyright (C) 2014  yoku0825
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
########################################################################

use strict;
use warnings;
use Getopt::Long qw/:config bundling gnu_compat no_ignore_case posix_default/;

### aggrigation unit. "h|hour" => per hour, "m|minute" => per minute, "s|second" => per second.
my $cell= "m";
GetOptions("cell=s"       => \$cell,
           "help|usage|h" => \my $usage) or die;
usage() if $usage;
my $header_parser= set_parser($cell);

my ($time_string, $count_hash);

### read from stdin.
while (<>)
{
  ### parsing datetime from comment line.
  if (/$header_parser/)
    {$time_string= $1;}

  ### parsing dml-line (only parse simple INSERT, UPDATE, DELETE, REPLACE)
  elsif (/^(insert|update|delete|replace)\s+(?:(?:into|from)?)\s+(\S+?)\s+/i)
  {
    my ($dml, $table)= (lc($1), lc($2));
    $table =~ s/`//g;

    if ($time_string && $dml && $table)
    {
      $count_hash->{$time_string}->{$table}->{$dml}++;
      $time_string= $dml= $table= "";
    }
  }
}

### after reading all lines, printing them all.
foreach my $time (sort(keys(%$count_hash)))
{
  foreach my $tbl (sort(keys(%{$count_hash->{$time}})))
  {
    foreach my $stmt qw/insert update delete replace/
    {
      if (defined($count_hash->{$time}->{$tbl}->{$stmt}))
        {printf("%s\t%s\t%s\t%d\n", $time, $tbl, $stmt, $count_hash->{$time}->{$tbl}->{$stmt});}
    }
  }
}

exit 0;


### set regexp for parsing datetime.
sub set_parser
{
  my ($granuality)= @_;
  my $parse;

  if ($granuality eq "h" || $granuality eq "hour")
    {$parse= qr/^#(\d{2}\d{2}\d{2}\s+\d{1,2}):\d{2}:\d{2}/;}
  elsif ($granuality eq "m" || $granuality eq "minute" || $granuality eq "1m")
    {$parse= qr/^#(\d{2}\d{2}\d{2}\s+\d{1,2}:\d{2}):\d{2}/;}
  elsif ($granuality eq "10m")
    {$parse= qr/^#(\d{2}\d{2}\d{2}\s+\d{1,2}:\d{1})\d{1}:\d{2}/;}
  elsif ($granuality eq "s" || $granuality eq "second")
    {$parse= qr/^#(\d{2}\d{2}\d{2}\s+\d{1,2}:\d{2}:\d{2})/;}
  else
    {$parse= qr/^#(\d{2}\d{2}\d{2})\s+\d{1,2}:\d{2}:\d{2}/;}

  return $parse;
}


sub usage
{
  print << "EOS";
$0 is aggregator of mysqlbinlog's output.

expample:
  \$ mysqlbinlog --start-datetime="2012-03-04" --stop-datetime="2012-03-05" mysql-bin.000012 | $0 --cell m
  ..
  140823 23:36    insert  57
  140823 23:36    update  580
  140823 23:36    replace 5
  140823 23:37    insert  86
  140823 23:37    update  520
  140823 23:37    replace 6
  140823 23:38    insert  87
  140823 23:38    update  671
  140823 23:38    replace 6
  ..

options:
  --cell=string         Unit of aggregation.
                        Currentry supported are,
                          "s", "second",
                          "m", "minute", "1m",
                          "10m", 
                          "h", "hour"
  --groupby=string      "time", "statement", "table", "all"
  --usage, --help, -h   Print this message.
EOS
  exit 0;
}
