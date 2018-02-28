package CodeMonkey::Parse::Perl;

use Rival::PPI::_Util;

use Data::Dumper;
use PPI::Document;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / /

  ];

sub init {
  my ($self,%args) = @_;
}

sub ExtractFunctions {
  my ($self,%args) = @_;
  my $element;
  if ($args{Element}) {
    $element = $args{Element};
  } elsif ($args{File}) {
    $element = PPI::Document->new($args{File});
  } elsif ($args{String}) {
    my $string = $args{String};
    $element = PPI::Document->new(\$string);
  }

  # print Dumper($element);
  my $res = $element->find
    (
     sub { $_[1]->isa('PPI::Statement::Sub') and $_[1]->name }
    );
  my $ref = ref $res;
  my @functions;
  if ($ref eq "ARRAY") {
    # go ahead and get the function body
    foreach my $item (@$res) {
      push @functions,
	{
	 Name => $item->name,
	 Body => NodeSerialize
	 (Node => $item),
	};
    }
  }
  return \@functions;
}

1;
