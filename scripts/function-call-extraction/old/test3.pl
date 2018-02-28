#!/usr/bin/perl -w

use Data::Dumper;
use PPI::Document;

my $d = PPI::Document->new("example3.pl");
print Dumper($d);
