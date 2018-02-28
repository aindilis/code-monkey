package CodeMonkey::CamelCase;

use PerlLib::Dictionary;

use Data::Dumper;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       => [ qw / MyDictionary / ];

sub init {
  my ($self,%args) = @_;
  $self->MyDictionary
    ($args{Dictionary} || PerlLib::Dictionary->new
     (
      DictFiles => [
		    "/usr/share/dict/american-english-insane",
		    "/var/lib/myfrdcsa/codebases/internal/code-monkey/scripts/camelcase-dictionary-creator/camelcase-dictionary.txt",
		   ],
      Verbose => 1,
      CaseSensitive => 0,
     ));
}

sub GetBestCamelCase {
  my ($self,%args) = @_;
  my $w = $args{Word};
  my @x = $self->GetAllWords(Word => $w);
  my $y = $self->BestBreakdown(ArrayRef => \@x);
  #   print Dumper({
  # 		X => \@x,
  # 		Y => $y,
  # 	       });
  return join("",map {s/\b(\w)/\U$1/g; ; $_} @$y);
}

sub BestBreakdown {
  my ($self,%args) = @_;
  my $sol = $args{ArrayRef};
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
  my ($self,%args) = @_;
  my $w = $args{Word};
  my @w1 = split //,$w;
  my @res;
  while (@w1) {
    my $nw = join("",@w1);
    if ($self->DictTest(Word => $nw)) {
      push @res, $nw;
    }
    pop @w1;
  }
  return @res;
}

sub GetAllWords {
  my ($self,%args) = @_;
  my $w = $args{Word};
  if (! defined $w) {
    return;
  } elsif (length($w) == 1 and $w !~ /[ai]/i) {
    return;
  }
  my @w1 = split //,$w;
  my @res = $self->GetPrefixWords(Word => $w);
  my @sol;
  foreach my $r (@res) {
    my @w2 = @w1;
    my @rem = splice(@w2,length($r),length($w) - length($r));
    my @ret = ($r);
    my $r2 = join("",@rem);
    if ($self->DictTest(Word => $r2)) {
      return ([$r,$r2]);
    } else {
      foreach my $l ($self->GetAllWords(Word => $r2)) {
	unshift @$l, $r;
	push @sol, $l;
      }
    }
  }
  return @sol;
}

sub DictTest {
  my ($self,%args) = @_;
  my $w = $args{Word};
  if (length($w) > 2) {
    if ($w =~ /^[0-9]+$/) {
      return 1;
    } elsif ($self->MyDictionary->Lookup
	     (Word => $w)) {
      return 1;
    }
  }
}

1;

# test data
# BestBreakdown BreakdownWord Choose Clean DeclareEvent DeclareTask EvalDomain Execute ExportCurrentDomain ExportCurrentWorldModel Generate GetAllWords GetPrefixWords HasArray InOrderTraverseDomain Light LoadCurrentWorldModel LoadDataFromFile LoadDomain Loop ParseDomainFile PerformTaskList PrepareForEvent PrettyGenerate PrintDomain PrintEvent ProcessInput Quick Quicker ReportEvent SaveCurrentWorldModel SaveDataToFile SaveDomain ShowCurrentDomain WalkThrough init

# process other files containing subroutines, so that we can find things like EvalDomain -> EvaLDomain, by adding eval to the dictionary

# add language modeling to avoid things like: PrepareForeVent
