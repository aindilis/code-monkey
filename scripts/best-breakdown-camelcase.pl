#!/usr/bin/perl -w

use PerlLib::Dictionary;

use Data::Dumper;

# test data
# BestBreakdown BreakdownWord Choose Clean DeclareEvent DeclareTask EvalDomain Execute ExportCurrentDomain ExportCurrentWorldModel Generate GetAllWords GetPrefixWords HasArray InOrderTraverseDomain Light LoadCurrentWorldModel LoadDataFromFile LoadDomain Loop ParseDomainFile PerformTaskList PrepareForEvent PrettyGenerate PrintDomain PrintEvent ProcessInput Quick Quicker ReportEvent SaveCurrentWorldModel SaveDataToFile SaveDomain ShowCurrentDomain WalkThrough init

# process other files containing subroutines, so that we can find things like EvalDomain -> EvaLDomain, by adding eval to the dictionary

# add language modeling to avoid things like: PrepareForeVent

my $dict = PerlLib::Dictionary->new
  (
   Verbose => 1,
   CaseSensitive => 0,
  );

foreach my $w (@ARGV) {
  my @x = GetAllWords($w);
  my $y = BestBreakdown(\@x);
  print join("",map {s/\b(\w)/\U$1/g; ; $_} @$y)."\n";
}

sub BestBreakdown {
  my $sol = shift;
  my $min = 1000;
  my $ans;
  foreach my $s (@$sol) {
    if (scalar @$s < $min) {
      $min = scalar @$s;
      $ans = $s;
    }
  }
  return $ans;
}

sub GetPrefixWords {
  my $w = shift;
  my @w1 = split //,$w;
  my @res;
  while (@w1) {
    my $nw = join("",@w1);
    if (DictTest($nw)) {
      push @res, $nw;
    }
    pop @w1;
  }
  return @res;
}

sub GetAllWords {
  my $w = shift;
  if (length($w) == 1 and $w !~ /[ai]/i) {
    return;
  }
  my @w1 = split //,$w;
  my @res = GetPrefixWords($w);
  my @sol;
  foreach my $r (@res) {
    my @w2 = @w1;
    my @rem = splice(@w2,length($r),length($w) - length($r));
    my @ret = ($r);
    my $r2 = join("",@rem);
    if (DictTest($r2)) {
      return ([$r,$r2]);
    } else {
      foreach my $l (GetAllWords($r2)) {
	unshift @$l, $r;
	push @sol, $l;
      }
    }
  }
  return @sol;
}

sub DictTest {
  my $w = shift;
  if ($w =~ /^[0-9]+$/) {
    return 1;
  } elsif ($dict->Lookup(Word => $w)) {
    return 1;
  }
}
