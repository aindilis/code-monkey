#!/usr/bin/perl -w

use Data::Dumper;
use PPI::Document;
use PPI::Structure::Block;

my $d = PPI::Document->new("example.pl");
# print Dumper($d);

my $children = $d->{children}->[2]->{children}->[0]->{children}->[2]->{children};

my $c = `cat block.dat`;
my $VAR1;
eval $c;
my $block = $VAR1;
$VAR1 = undef;

# print Dumper($block);
$block->{children} = $children;

print $block->content."\n";
