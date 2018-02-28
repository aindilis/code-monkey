#!/usr/bin/perl -w

use Data::Dumper;
use PPI::Document;
use PPI::Dumper;

my $file = shift @ARGV;
my $doc = PPI::Document->new($file);
my $dumper = PPI::Dumper->new($doc);;
$dumper->print;
