#!/usr/bin/perl -w

use PerlLib::EasyPersist;

use Data::Dumper;
use IO::File;
use PPI::Document;
use PPI::Structure::Block;

my $blocktext = `cat block.dat`;
my @items;
my $functioncalls = {};

sub ProcessFiles {
  my %args = @_;
  my $resultfile = "/var/lib/myfrdcsa/codebases/internal/code-monkey/data/results.pl";
  my $fh = IO::File->new;
  $fh->open("> $resultfile") or die "cannot open file for reading, $resultfile\n";
  foreach my $file (@{$args{Files}}) {
    if (-f $file) {
      my $d = PPI::Document->new($file);
      ExtractFunctionCalls(Element => $d);
    }
  }
  print $fh Dumper($functioncalls);
  $fh->close;
}

sub ExtractFunctionCalls {
  my %args = @_;
  my $element = $args{Element};
  my $state = "start";
  my $record = 0;
  my $functionname;
  my @items;
  my @children;
  if (exists $element->{children}) {
    foreach my $child ($element->children) {
      # see if this isn't it
      if (! $record) {
	ExtractFunctionCalls
	  (
	   Element => $child,
	  );
      }
      if ($state eq "word") {
	if (ElementIsWhitespace($child) or
	    ElementIsParens($child)) {
	  # this is a subroute call
	  $record = 1;
	}
      } elsif ($state eq "arrow") {
	if (ElementIsWord($child)) {
	  $state = "word";
	  $functionname = $child->content;
	  push @children, $child;
	}
      } elsif ($state eq "start" or $state eq "word") {
	if (ElementIsArrow($child)) {
	  $state = "arrow";
	}
      } else {
	$state = "start";
	$record = 0;
      }
      if ($record == 1) {
	push @children, $child;
      }
    }
    if (scalar @children) {
      my $content = PrintFunction(\@children);
      print Dumper({
		    Function => $functionname,
		    Content => $content,
		   }) if $debug;
      $functioncalls->{$functionname}->{$content}++;
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
   Files => \@items,
  );
