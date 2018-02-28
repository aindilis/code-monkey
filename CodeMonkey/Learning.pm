package CodeMonkey::Learning;

use Manager::Dialog qw ();

use Data::Dumper;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       => [ qw / / ];

sub init {
  my ($self,%args) = @_;
}

1;
