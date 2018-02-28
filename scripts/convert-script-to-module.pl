#!/usr/bin/perl -w

# this system should be adapted should to use actual refactorings

use BOSS::Config;
use CodeMonkey::CamelCase;
use File::Slurp;
use Manager::Dialog qw(Approve QueryUser);

use Data::Dumper;

my $specification = "
	-i <inputfile>		Input script file
	-o <outputfile>		Output module file

	-m <modulename>		Module name
";

my $config = BOSS::Config->new
  (Spec => $specification,
   ConfFile => "");
my $conf = $config->CLIConfig;

my $camelcase = CodeMonkey::CamelCase->new();
die "Usage: convert-script-to-module.pl -i <input script> -o <output module> -m <module name>\n" unless (exists $conf->{'-i'} and
	    -f $conf->{'-i'} and
	    exists $conf->{'-o'} and
	    exists $conf->{'-m'});
my $f = $conf->{'-i'};
my $of = $conf->{'-o'};
my $replacements = {};

my $c = read_file($f);

my $pkgname = $conf->{'-m'};
my $pkgfile = $pkgname.".pm";
$pkgfile =~ s|::|/|g;

# get rid of #!/usr/bin/perl -w
# add the package title
$c =~ s/^#!\/usr\/bin\/perl (-w)?//s;

my $execute = 0;
if ($c !~ /^sub Execute \{/m) {
  $execute = 1;
}

# create Execute if it doesn't exist
# extract the real subs

my @bsubs;
my @subs;
my @nsubs;
my $i = 0;
my $subs = 0;
my @lines = split /\n/, $c;
my $subsh = {};

while (@lines) {
  my $l = shift @lines;
  if ($l =~ /^sub (.*) \{/) {
    $subsh->{$1} = 1;
    $subs = 1;
    my $done = 0;
    my @m;
    push @m, $l;

    # get the args right
    my $x = shift @lines;
    if ($x =~ /^\s*my (\S+) = .*$/) {
      my $y = $1;
      $y =~ s/^\(//;
      $y =~ s/\)$//;
      push @m, "  my (\$self,$y) = \@_;"
    } else {
      unshift @lines, $x;
      push @m, "  my (\$self) = \@_;"
    }
    do {
      my $l = shift @lines;
      if ($l =~ /^\}/) {
	push @m, $l;
	$done = 1;
      } else {
	push @m, $l;
      }
    } while (@lines and ! $done);
    push @subs, join("\n",@m) if @m;
    $subs = join("\n",@lines);
  } elsif ($subs) {
    my $done = 0;
    my @m;
    do {
      my $l = shift @lines;
      if ($l =~ /^sub /) {
	unshift @lines,$l;
	$done = 1;
      } elsif ($l =~ /^\}/) {
	push @m, "  $l";
	$done = 1;
      } else {
	push @m, "  $l";
      }
    } while (@lines and ! $done);
    push @nsubs, join("\n",@m) if @m;
  } else {
    my $done = 0;
    my @m;
    push @m, $l;
    do {
      my $l = shift @lines;
      if ($l =~ /^sub /) {
	unshift @lines,$l;
	$done = 1;
      } elsif ($l =~ /^\}/) {
	push @m, $l;
	$done = 1;
      } else {
	push @m, $l;
      }
    } while (@lines and ! $done);
    push @bsubs, join("\n",@m) if @m;
  }
}

# now extract all the init stuff from bsubs, and nsubs
my $bsubs = join("\n",@bsubs);
my @isubs;
my @comments;

@lines = split /\n/,$bsubs;
my $uses = {};
my $attributes = {};
while (@lines) {
  my $l = shift @lines;
  if ($l =~ /^use (.*)$/) {
    my @m;
    if ($l !~ /;\s*$/) {
      while ($l !~ /;\s*$/) {
	push @m, $l;
	$l = shift @lines;
      }
      push @m, $l;
      $uses->{join("\n",@m)} = 1;
    } else {
      $uses->{$l} = 1;
    }
  } elsif ($l =~ /^\s*\#/) {
    push @comments, $l;
  } elsif ($l =~ /^\s*(my )?(\S+)\s*=\s*(.*)$/) {
    my @m;
    if ($l !~ /;\s*$/) {
      while ($l !~ /;\s*$/) {
	push @m, $l;
	$l = shift @lines;
      }
      push @m, $l;
      $attributes->{join("\n",@m)} = 1;
    } else {
      $attributes->{$l} = 1;
    }
  }
}

# calculate titles
my @myuses;
my @nouses;
my @codebases = qw(Manager);
my $regex = join("|",@codebases);
foreach my $key (sort keys %$uses) {
  if ($key =~ /use ($regex)/i) {
    push @myuses, $key;
  } else {
    push @nouses, $key;
  }
}

# calculate attributes
my %fattributes;
my %attreplace;
# print Dumper($attributes);
foreach my $key (keys %$attributes) {
  if ($key =~ /^\s*(my )?\$(\S+?)\s*=\s*(.*)\s*;\s*?$/s) {
    # fix up the name
    my $originalname = $2;
    my $values = $3;
    my $modifiedname = $originalname;
    $modifiedname =~ s/\b(\w)/\U$1/g;
    my $newname = GetNewName
      (Name => $modifiedname);
    $newname = EditReplace(
			   OriginalName => $originalname,
			   ModifiedName => $modifiedname,
			   NewName => $newname,
			  );
    $fattributes{$newname} = $values;
    $attreplace{$originalname} = $newname;
    push @isubs, "  \$self->$newname($values);";
  }
}

sub EditReplace {
  my %args = @_;
  if (! exists $replacements->{$args{OriginalName}}) {
    print Dumper({ARGS => \%args});
    my $replacement = $args{NewName};
    while (! Approve("Correct? <<<$replacement>>> ")) {
      $replacement = QueryUser("Please enter correction for <<<$replacement>>>: ");
    }
    $replacements->{$args{OriginalName}} = $replacement;
  }
  return $replacements->{$args{OriginalName}};
}

sub GetNewName {
  my %args = @_;
  my $ret = $camelcase->GetBestCamelCase
    (Word => $args{Name});
  # print Dumper({RET => $ret});
  return $ret || $args{Name};

  #   my $res = `/var/lib/myfrdcsa/codebases/internal/code-monkey/scripts/best-breakdown-camelcase.pl $args{Name}`;
  #   my @newvalues = split /\n/, $res;
  #   shift @newvalues;
  #   shift @newvalues;
  #   return shift @newvalues;
}

# print Dumper($attributes);

# move all expressions outside of subs into Execute
$c =
  join("\n\n",
       join("\n",@comments),
       join("\n",@myuses),
       join("\n",@nouses),
       join("\n",
	    (
	     "use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / ".join(" ", sort keys %fattributes).
	     " /

  ];",
	     "",
	     "sub init {",
	     "  my (\$self,\%args) = \@_;",
	     join("\n",@isubs),
	     "}",
	     "",
	     "sub Execute {",
	     "  my (\$self,\%args) = \@_;",
	     join("\n",@nsubs),
	     "}",
	    )
	   ),
       join("\n\n",@subs),
      );

# add the 1; at the end
if ($c !~ /1;\s*$/sg) {
  $c =~ s|$|\n\n1;\n|s;
}



# move all global variables into init and convert them to attributes

# adjust all tokens

# fix all functions

foreach my $sub (keys %$subsh) {
  $c =~ s/\b$sub\b/\$self->$sub/gs;
  $c =~ s/sub \$self->$sub /sub $sub /gs;
}

foreach my $attr (keys %attreplace) {
  my $nattr = $attreplace{$attr};
  $c =~ s/\$$attr->/\$self->$nattr->/gs;
  # $c =~ s/\$$attr\b/\$self->$nattr/gs;
  $c =~ s|\$$attr\b|\$self->$nattr|gs;
}

$c =~ s/\@ARGV/\@\{\$args\{Items\}\}/g;

$c = "package $pkgname;\n\n".$c;

# - if I use this package on itself that would be hilarious.

my $OUT;

open(OUT, ">$of") or die "cannot open outfile <$of>\n";
print OUT $c;
close(OUT);

if (1) {
  my $last = $pkgname;
  $last =~ s/.*:://;
  my $name = lc($last);
  $c = join("\n",
	    (
	     "#!/usr/bin/perl -w",
	     "",
	     "use $pkgname;",
	     "",
	     "my \$$name = $pkgname->new();",
	     "\$$name->Execute(Items => \\\@ARGV);"
	    ));
  print $c."\n";
}


# some features that could be added:

# convert file locations to $UNIVERSAL::systemdir."/data/<file>";

# needs to be sure to get all instances and to put the attributes in
# the right order

# handle all strange cases for $this to $self->This

# also locate all globals and convert them to attributes (even when
# they are autovivified)

# prevent these VVVV
#  my $f = $self->F;
#  $self->C(`cat "{$self->F}"`);

# my {$self->C} = "insert into categories values (NULL,".$self->Mysql->DBH->quote($catname).",NULL,NULL)";

# prevent overwriting local variables with attributes


# try to find a smart way to do this later, using actual parsing, duh!

#!/usr/bin/perl -w




# note that the ${$self->This} is interpretted as a hash,


# handle @lists and %hashes


# have the ability to convert items from ($self,$sentence) to ($self, $args);

# have the ability to selectively apply any of these fixes in independent stages.
