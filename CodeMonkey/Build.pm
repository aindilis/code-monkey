package CodeMonkey::Build;

use Manager::Dialog qw (SubsetSelect ApproveCommands);

use Data::Dumper;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       => [ qw / BuildDir State / ];

sub init {
  my ($self,%args) = @_;
  $self->BuildDir($args{BuildDir} || `pwd`);
}

sub Build {
  my ($self,%args) = @_;
  # find out what state the object is in
  if (-d $self->BuildDir) {
    my $dir = $self->BuildDir;
    chdir $dir;
    $self->Make;
  }
}

sub Configure {
  my ($self,%args) = @_;
  my $build = `./configure`;
  print $build."\n";
  if ($build =~ /error/i) {
    # apparently there's been an error
    if ($build =~ /You don\'t seem to have (.+) installed/) {
      CheckForLibrary($1);
    }
  }
}

sub Make {
  my ($self,%args) = @_;
  my $make = `make`;
  print $make."\n";
}

sub CheckForLibrary {
  my ($self,%args) = @_;
  my $library = $args{Library};
  print "<$library>\n";
  my $results = `apt-cache search $library`;
  my $item = {};
  foreach my $line (split /\n/, $results) {
    $line =~ /^(.+) - (.+)$/;
    $item->{$line} = $1;
  }
  my @res;
  foreach my $match
    (SubsetSelect
     (Set => [keys %$item],
      Selection => {})) {
      push @res, $item->{$match};
    }
  ApproveCommands
    (Commands =>
     ["sudo apt-get install ".join(" ",@res)],
     Method => "parallel");
}

1;
