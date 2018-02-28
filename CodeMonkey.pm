package CodeMonkey;

use BOSS::Config;
use CodeMonkey::Build;
use CodeMonkey::Refactory;

use Data::Dumper;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       => [ qw / Conf MyBuild / ];

sub init {
  my ($self,%args) = (shift,@_);
  $specification = "
	-c <codebase>			CodeBase to affect
	-f <files>...			Files to affect
	--beautify			Tidy up code
	--enforce-standards		Enforce content standards (project naming conventions,etc)
	--convert-to-oo			Convert codebase to object oriented Perl
	--change-name <dest>		Change the name of a codebase through the code
	-b <directory>			Build directory
";

  $self->Conf(BOSS::Config->new
	      (Spec => $specification,
	       ConfFile => ""));
  my $conf = $self->Conf->CLIConfig;
}

sub Execute {
  my ($self,%args) = (shift,@_);
  my $conf = $self->Conf->CLIConfig;
  if (exists $conf->{'--beautify'}) {
    $self->Beautify(Files => $conf->{'-f'});
  }
  if (exists $conf->{'--convert-to-oo'}) {
    $self->ConvertToOO(CodeBase => $conf->{'-c'});
  }
  if (exists $conf->{'--change-name'}) {
    $self->ChangeName
      (CodeBase => $conf->{'-c'},
       Name => $conf->{'--change-name'});
  }
  if (exists $conf->{'-b'}) {
    $self->MyBuild
      (CodeMonkey::Build->new
       (BuildDir => $conf->{'-b'}));
    $self->MyBuild->Build;
  }
}

sub Beautify {
  my ($self,%args) = (shift,@_);
  # use perltidy to clean up source
  print Dumper($args{Files});
}

sub ConvertToOO {
  my ($self,%args) = (shift,@_);
  my $dir = ConcatDir("/var/lib/myfrdcsa/codebases/internal",
		      ICodebaseP(QueryUser("CodeBase Regex")));
  $self->ChangeName(CodeBase => $codebase);
}

sub ChangeName {
  my ($self,%args) = (shift,@_);
  $codebase = $args{CodeBase};

  my $start = QueryUser("Start?");
  my $end = QueryUser("End?");

  # for instance <Mach><MV>
  $dir1 = ConcatDir($dir,$start);
  foreach my $file (split /\n/,`find $dir1 -follow`) {
    # first convert all instances
    my $contents = `cat $file`;
    #
    print $file."\n";
  }
}

1;
