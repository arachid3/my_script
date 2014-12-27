#!/usr/bin/perl

use strict;
use warnings;
use Time::Piece;
use DBI;

my $conn= DBI->connect("dbi:mysql:information_schema;mysql_socket=/usr/mysql/5.6.22/data/mysql.sock", "root", "");
my $sql = "SELECT variable_value FROM global_status WHERE variable_name= ?";
my $interval= 3;
my $counter= {};
my $escape= {red  => "\033[31;1m",
             blue => "\033[34;1m",
             end  => "\033[0m"};

while ()
{
  my $tp= Time::Piece::localtime();
  printf("%s\t", $tp->strftime("%H:%M:%S"));
  foreach ({name => "Uptime",  color => "red"},
           {name => "Queries", color => "blue"})
  {
    my $name = $_->{name};
    my $color= $_->{color};

    my $num= $conn->selectrow_arrayref($sql, undef, $name)->[0];
    if ($counter->{$name}->{old})
    {
      printf("%s%s%s", $escape->{$color}, "*" x (($num - $counter->{$name}->{old}) / $interval), $escape->{end});
    }
    $counter->{$name}->{old}= $num;
  }
  print "\n";
  sleep $interval;
}

exit 0;
