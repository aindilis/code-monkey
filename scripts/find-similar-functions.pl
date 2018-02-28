#!/usr/bin/perl -w

use CodeMonkey::Parse::Perl;
use PerlLib::EasyPersist;
use PerlLib::SwissArmyKnife;
use SoftwareIndexer::Util::Similarity;

use Data::Dumper;
use IO::File;
use PPI::Document;
use PPI::Structure::Block;

my $blocktext = `cat block.dat`;
my @items;
my $functions = {};
my $similarity = SoftwareIndexer::Util::Similarity->new;
my $perl = CodeMonkey::Parse::Perl->new;

sub ProcessFiles {
  my %args = @_;
  my $resultfile = "/var/lib/myfrdcsa/codebases/internal/code-monkey/data/function-similarity-results.pl";
  my $data;
  if (! -f $resultfile) {
    print "Processing Files...\n";
    my $fh = IO::File->new;
    $fh->open("> $resultfile") or die "cannot open file for reading, $resultfile\n";
    foreach my $file (@{$args{Files}}) {
      if (-f $file) {
	print "\t$file\n";
	my $d = PPI::Document->new($file);
	foreach my $entry (@{$perl->ExtractFunctions(Element => $d)}) {
	  $functions->{$file}->{$entry->{Name}} = $entry->{Body};
	}
      }
    }
    print $fh Dumper($functions);
    $fh->close;
    print "Done Processing Files.\n";
  } else {
    my $c = read_file($resultfile);
    $functions = DeDumper($c);
  }

  my $searchname;
  my $searchbody;
  if (-f $args{File}) {
    my $d1 = PPI::Document->new($args{File});
    foreach my $entry (@{$perl->ExtractFunctions(Element => $d1)}) {
      if ($entry->{Name} eq $args{FunctionName}) {
	$searchname = $entry->{Name};
	$searchbody = $entry->{Body};
      }
    }
  }

  print "Calculating document similarity...\n";
  my $score = {};
  foreach my $file (sort keys %$functions) {
    print "$file\n";
    foreach my $name (keys %{$functions->{$file}}) {
      $score->{$file."---".$name} = $similarity->ComputeSimilarity
	(
	 Doc1 => $searchbody,
	 Doc2 => $functions->{$file}->{$name},
	);
    }
  }
  print "Done calculating document similarity.\n";

  my @res = sort {$score->{$b} <=> $score->{$a}} keys %$score;
  foreach my $id (splice @res, 0, 20) {
    if ($id =~ /^(.+)---(.+)$/) {
      my $file = $1;
      my $name = $2;
      print "$file: $name\n";
    }
  }
}

sub ElementIsArrow {
  my $item = shift;
  my $ref = ref $item;
  if ($ref eq 'PPI::Token::Operator' and $item->{content} eq '->') {
    return 1;
  }
}

sub ElementIsWord {
  my $item = shift;
  my $ref = ref $item;
  if ($ref eq 'PPI::Token::Word') {
    return 1;
  }
}

sub ElementIsWhitespace {
  my $item = shift;
  my $ref = ref $item;
  if ($ref eq 'PPI::Token::Whitespace') {
    return 1;
  }
}

sub ElementIsParens {
  my $item = shift;
  my $ref = ref $item;
  if ($ref eq 'PPI::Structure::List') {
    return 1;
  }
}

sub PrintFunction {
  my $VAR1;
  eval $blocktext;
  my $block = $VAR1;
  $VAR1 = undef;

  # print Dumper($block);
  $block->{children} = (shift);

  return $block->content;
}

sub LoadItems {
  my %args = @_;
  # in the future, be more thorough...
  my $persist = PerlLib::EasyPersist->new;
  my $overwrite = 0;
  my $scripts = $persist->Get
    (
     Command => "`boss list_scripts`",
     Overwrite => $overwrite,
    );

  my $modules = $persist->Get
    (
     Command => "`boss list_modules`",
     Overwrite => $overwrite,
    );

  if ($scripts->{Success}) {
    foreach my $script (split /\n/, $scripts->{Result}) {
      push @items, $script;
    }
  }
  if ($modules->{Success}) {
    foreach my $module (split /\n/, $modules->{Result}) {
      push @items, "/usr/share/perl5/".$module;
    }
  }
}

LoadItems();
ProcessFiles
  (
   File => $ARGV[0],
   FunctionName => $ARGV[1],
   Files => \@items,
  );
