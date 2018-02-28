package CodeMonkey::Refactory;

use Data::Dumper;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       => [ qw / Files / ];

sub init {
  my ($self,%args) = (shift,@_);
}

1;
