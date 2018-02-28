package Out;

# system to try to come up with mappings between cyc and a sentence.
# this may be destined to be in termios

use Manager::Dialog qw(Message);

use Data::Dumper;
use Lingua::EN::Sentence qw(get_sentences);
use Lingua::EN::Tagger;
use String::Tokenizer;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / Constants Sentmap Tagger Tokenizer /

  ];

sub init {
  my ($self,%args) = @_;
  $self->Tokenizer(String::Tokenizer->new());
  $self->Sentmap({});
  $self->Constants({});
  $self->Tagger(Lingua::EN::Tagger->new
		(stem => 0));
}

sub Execute {
  my ($self,%args) = @_;
  $self->ProcessCycConstants;
  foreach my $f (@{$args{Items}}) {
    $self->ProcessFile($f);
  }
  print Dumper($sentmap);
}

sub ProcessCycConstants {
  my ($self) = @_;
  # these are initial starting points for a given term
  Message(Message => "Processing Cyc Constants");
  foreach my $l (split /\n/,`cat consts`) {
    $constants->{$l} = {};
    $lc->{lc($l)} = $l;
  }
}

sub ProcessFile {
  my ($self,$f) = @_;
  Message(Message => "Processing File");
  my $c = `cat "$f"`;
  my $s = get_sentences($c);
  foreach my $sentence (@$s) {
    $self->ProcessSentence($sentence);
  }
}

sub ProcessSentence {
  my ($self,$sentence) = @_;

  # do noun phrases, see what that yields
  my %nps;
  if (1) {
    my $tagged_text = $self->Tagger->add_tags( $sentence );
    %nps = $self->Tagger->get_noun_phrases($tagged_text);
  } else {
    %nps = $self->Tagger->get_words($sentence);
  }
  # print Dumper(\%nps);
  my $matches = {};
  foreach my $np (keys %nps) {
    my $args = $self->MatchNP($np);
    if (ref $args eq "HASH") {
      $matches->{$args->{Phrase}} = $args->{GAF};
    }
  }
  $sentmap->{$sentence}->{Matches} = $matches;

  # now search for n-grams
  $self->Tokenizer->tokenize($sentence);
  my @tokens = $self->Tokenizer->getTokens();

  my @ngrams = $self->GetAllNGrams
    (MaxLength => 3,
     Tokens => \@tokens);
  # print Dumper(\@ngrams);
  my $matches = {};
  foreach my $ngram (@ngrams) {
    my $np = join("",@$ngram);
    my $args = $self->CheckConstant($np);
    if (ref $args eq "HASH") {
      $matches->{$args->{Phrase}} = $args->{GAF};
    }
  }
  foreach my $key (keys %$matches) {
    $sentmap->{$sentence}->{Matches}->{$key} = $matches->{$key};
  }
}

sub GetAllNGrams {
  my ($self,%args) = @_;
  my @tokens = @{$args{Tokens}};
  my @res;
  foreach my $i (2..$args{MaxLength}) {
    my @cp = @tokens;
    my $size;
    do {
      my @ng;
      $size = scalar @cp;
      foreach my $j (1..$i) {
	push @ng, shift @cp;
      }
      if (scalar @ng == $i) {
	push @res, \@ng;
      }
      my @cp2 = @ng;
      shift @cp2;
      unshift @cp, @cp2;
    } while ($size >= $i);
  }
  return @res;
}

sub ConstantApropos {
  my ($self,$search) = @_;
  my @res;
  foreach my $c (keys %$constants) {
    if ($c =~ /$search/i) {
      push @res, $c;
    }
  }
  return \@res;
}

sub MatchTokens {
  my ($self,$np) = @_;
  # now we have to look at all of these constants and see which ones fit
  # best, if at all
  # first check for exact matches
  $self->Tokenizer->tokenize($np);
  foreach my $w ($self->Tokenizer->getTokens()) {
    if ($w) {
      if ($w =~ /^[\s\w]+$/) {
	if (exists $lc->{lc($w)}) {
	  return {Phrase => "$w",
		  GAF => "\#\$".$lc->{lc($w)}};
	} else {
	  #       my $matches = $self->ConstantApropos($w);
	  #       foreach my $m (@$matches) {
	  #	print "$w -- $m\n"
	  #       }
	}
      }
    }
  }
}

sub CheckConstant {
  my ($self,$w) = @_;
  if (exists $lc->{lc($w)}) {
    return {Phrase => "$w",
	    GAF => "\#\$".$lc->{lc($w)}};
  }
}

sub MatchNP {
  my ($self,$np) = @_;
  my $m = $self->CheckConstant($np);
  return $m if $m;
  my $st = $np;
  $st =~ s/\s+//g;
  # print $st."\n";
  my $m = $self->CheckConstant($st);
  return $m if $m;
}

1;
