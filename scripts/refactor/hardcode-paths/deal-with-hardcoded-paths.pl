#!/usr/bin/perl -w

use Data::Dumper;
use PPI;

# detect hardcoded paths and replace where possible

# take the file as input

my $path1 = "/var/lib/myfrdcsa";
my $path2 = '/var/lib/myfrdcsa';
foreach my $dir (split /\n/, `ls /var/lib/myfrdcsa`) {

}
system "/var/lib/myfrdcsa";

foreach my $file (@ARGV) {
  my $document = PPI::Document->new($file);
  print Dumper($document);
}
