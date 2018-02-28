#!/usr/bin/perl -w

use Data::Dumper;
use PPI;

my $search = "/var/lib/myfrdcsa/";
my @lines = split /\n/, `search-inside "$search"`;
shift @lines;
shift @lines;
my $files = {};
foreach my $line (@lines) {
  if ($line =~ /^(.+?):\s+(.+)$/) {
    my $file = $1;
    my $matchingline = $2;
    if (-f $file) {
      $files->{$file}++;
    }
  }
}

my $tmp = $search;
$tmp =~ s/\//\\\//g;
my $regex = qr/$tmp/;

# now, foreach file, run the PPI on it and find instances of atoms
# matching it, and their context

foreach my $file (sort keys %$files) {
  print "Using file <$file>\n";
  my $doc = PPI::Document->new($file);
  # now do the search for something matching that
  my $subnodes = $doc->find
    (
     sub { $_[1]->content =~ $regex }
    );
  foreach my $subnode (@$subnodes) {
    print NodeSerialize(Node => $subnode)."\n\n";
  }
  sleep 3;
}

sub NodeSerialize {
  my (%args) = @_;
  my $doc = PPI::Document->new();
  $doc->add_element(GetCopy(Node => $args{Node}));
  return $doc->serialize;
}

sub GetCopy {
  my (%args) = @_;
  my $VAR1 = undef;
  eval Dumper($args{Node});
  return $VAR1;
}
