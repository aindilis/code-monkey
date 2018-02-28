#!/usr/bin/perl -w

use Manager::Dialog qw(ApproveCommands);
use PerlLib::Util;

use Data::Dumper;
use File::Slurp;
use IO::File;
use PPI::Document;

# we need to parse a lot of perl programs I've written and extract out
# function and attribute names in order to build the camelcase
# dictionary

my $filesfile = "files.txt";
my $dictfile = "camelcase-dictionary.pl";
my $dictfiletxt = "camelcase-dictionary.txt";
my $names = {};
if (! -f $dictfiletxt) {
  if (! -f $dictfile) {
    if (! -f $filesfile) {
      ApproveCommands
	(
	 Commands => ["boss list_modules > $filesfile"],
	 Method => "parallel",
	 AutoApprove => 1,
	);
    }
    my @files2 = split /\n/, read_file($filesfile);
    # my @files = splice @files2, 0, 100;
    my @files = @files2;
    foreach my $file2 (@files) {
      my $file = "/usr/share/perl5/$file2";
      # use author identification to make sure I'm the author of it, or
      # just actually iterate over stuff we know I wrote
      if (-f $file) {
	print "$file\n";
	my $doc = PPI::Document->new($file);
	# extract out all the subs and attributes
	foreach my $sub (@{$doc->find( 'PPI::Statement::Sub' )}) {
	  my $name = $sub->name;
	  if ($name and $name =~ /[A-Z]/) {
	    $names->{$name}++;
	  }
	}
      }
    }

    my $fh = IO::File->new;
    $fh->open(">$dictfile") or die "cannot\n";
    print $fh Dumper($names);
    $fh->close;
  } else {
    $names = DeDumper(read_file($dictfile));
  }

  my $words = {};
  foreach my $name (sort keys %$names) {
    $name =~ s/([a-z])([A-Z])/$1 $2/g;
    $name =~ s/(.)([A-Z][a-z])/$1 $2/g;
    foreach my $word (split /\s/, $name) {
      $words->{$word}++;
    }
  }
  my $fh2 = IO::File->new;
  $fh2->open(">$dictfiletxt") or die "cannot 2\n";
  print $fh2 join("\n",sort keys %$words);
  $fh2->close;
}
