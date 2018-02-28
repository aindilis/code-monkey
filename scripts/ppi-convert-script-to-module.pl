#!/usr/bin/perl -w

# # # here is what needs to be done

# # move all global variables into init and convert them to attributes
# # locate all function invocations and perform substitution as
# # necessary
# # fix the init function
# # fix the init stuff to go from $ngrams = {}; to $self->Ngrams({});
# # fix the execute function

###### fix the arguments to subroutines to get $self

# use this package on itself
# ? adjust all tokens
# ? fix all functions
# fix the @ARGV income
# beautify the final code

# # # some features that could be added:

# this system should be adapted should to use actual refactorings
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

use BOSS::Config;
use CodeMonkey::CamelCase;
use Manager::Dialog qw(Approve QueryUser);

use Data::Dumper;
use File::Slurp;
use IO::File;
use PPI::Document;
use PPI::Dumper;

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
die "Usage: convert-script-to-module.pl -i <input script> -o <output module> -m <module name>\n" unless
  (exists $conf->{'-i'} and
   -f $conf->{'-i'} and
   exists $conf->{'-o'} and
   exists $conf->{'-m'});
my $f = $conf->{'-i'};
my $of = $conf->{'-o'};
my $replacements = {};

my $module = PPI::Document->new($f);

my $dumper = PPI::Dumper->new( $module );
# $dumper->print;

my $pkgname = $conf->{'-m'};
my $pkgfile = $pkgname.".pm";
$pkgfile =~ s|::|/|g;

# get rid of #!/usr/bin/perl -w
$module->prune( sub { $_[1]->content =~  /^#!\// } );

# check if it has an execute module
my $sub_nodes = $module->find
  (
   sub { $_[1]->isa('PPI::Statement::Sub') and $_[1]->name }
  );
my $execute = 0;
my $ppisubsh = {};
foreach my $sub (@$sub_nodes) {
  if ($sub->name eq "Execute") {
    $execute = 1;
  }
  $ppisubsh->{$sub->name} = 1;
  # get the args right

  my $subcopy = GetCopy(Node => $sub);

  # now find all the variables from this
  my $my_vars = $subcopy->find('PPI::Statement::Variable');
  foreach my $var (@$my_vars) {
    # print Dumper($var->variables)."\n";
    # print NodeSerialize(Node => $var)."\n";
    # extract out the item, and replace with the correct
  }
}

my @ppibsubs;
my @ppisubs;
my @ppinsubs;
my @ppibsubsprint;
my @ppisubsprint;
my @ppinsubsprint;
foreach my $node ($module->children) {
  if ($node->isa('PPI::Statement::Sub')) {
    push @ppisubs, $node;
    push @ppisubsprint, NodeSerialize(Node => $node);
  } else {
    if (scalar @ppisubs) {
      push @ppinsubs, $node;
      push @ppinsubsprint, NodeSerialize(Node => $node);
    } else {
      push @ppibsubs, $node;
      push @ppibsubsprint, NodeSerialize(Node => $node);
    }
  }
}

my @ppimyuses;
my @ppinouses;
my @ppicodebases = qw(Manager);
my $ppiregex = join("|",@ppicodebases);
my $ppiuses = {};
my $ppiattributes = {};
my @ppiattributeorder;
my @ppicomments = (
		   bless( {
			   'content' => '# ("created-by" "PPI-Convert-Script-To-Module")',
			  }, 'PPI::Token::Comment' ),
		  );
foreach my $node (@ppibsubs) {
  if ($node->isa('PPI::Statement::Include')) {
    $ppiuses->{$node->module} = $node;
    if ($node->module =~ /$ppiregex/i) {
      push @ppimyuses, $node;
    } else {
      push @ppinouses, $node;
    }
  } elsif ($node->isa('PPI::Statement::Variable')) {
    # now we need to split this thing up
    my $result = ProcessVariables(Node => $node);
    if ($result->{Success}) {
      # print Dumper($result->{Result});
      my $size = scalar @{$result->{Result}->{LHSs}};
      foreach my $i (0..($size - 1)) {
	$ppiattributes->{$result->{Result}->{LHSs}->[$i]} = $result->{Result}->{RHSs}->[$i];
	push @ppiattributeorder, $result->{Result}->{LHSs}->[$i];
      }
    }
  } elsif ($node->isa('PPI::Statement')) {
    push @ppinsubs, $node;
  } elsif ($node->isa('PPI::Token::Comment')) {
    push @ppicomments, $node;
  }
}

print Dumper({
	      ppi => {
		      ppiuses => $ppiuses,
		      ppiattributes => $ppiattributes,
		      ppicomments => \@ppicomments,
		      ppimyuses => \@ppimyuses,
		      ppinouses => \@ppinouses,
		     },
	     }) if 0;

my %ppifattributes;
my %ppiattreplace;
my @ppiisubs;
foreach my $originalname (@ppiattributeorder) {
  my $modifiedname = $originalname;
  $modifiedname =~ s/^(\$|\@|\%|\*|\&)//;
  $modifiedname =~ s/\b(\w)/\U$1/g;
  my $newname = GetNewName
    (Name => $modifiedname);
  #   $newname = EditReplace(
  # 			 OriginalName => $originalname,
  # 			 ModifiedName => $modifiedname,
  # 			 NewName => $newname,
  # 			);
  $ppifattributes{$newname} = $ppiattributes->{$originalname};
  $ppiattreplace{$originalname} = $newname;
  my $children;
  if (defined $ppifattributes{$newname}) {
    # print Dumper($ppifattributes{$newname});
    $children = [
		 bless( {
			 'children' => $ppifattributes{$newname},
			}, 'PPI::Statement::Expression' )
		];
  } else {
    $children = [];
  }
  push @ppiisubs, (
		   bless( {
			   'content' => '  '
			  }, 'PPI::Token::Whitespace' ),
		   bless( {
			   'children' => [
					  bless( {
						  'content' => '$self'
			  }, 'PPI::Token::Symbol' ),
		   bless( {
			   'content' => '->'
			  }, 'PPI::Token::Operator' ),
		   bless( {
			   'content' => $newname,
			  }, 'PPI::Token::Word' ),
		   bless( {
			   'finish' => bless( {
					       'content' => ')'
					      }, 'PPI::Token::Structure' ),
			   'children' => $children,
			   'start' => bless( {
					      'content' => '('
					     }, 'PPI::Token::Structure' )
			  }, 'PPI::Structure::List' ),
		   bless( {
			   'content' => ';'
			  }, 'PPI::Token::Structure' )
		  ]
}, 'PPI::Statement' ),
  bless( {
	  'content' => "\n"
	 }, 'PPI::Token::Whitespace' ),
);
}

  my @ppinsubsnew;
foreach my $ppithing (@ppinsubs) {
  if ($ppithing->isa('PPI::Statement')) {
      push @ppinsubsnew, (
			  bless( {
				  'content' => '  '
				 }, 'PPI::Token::Whitespace' ),
			  $ppithing,
			  bless( {
				  'content' => "\n"
				 }, 'PPI::Token::Whitespace' ),
			 );
    } else {
      my $ref = ref $ppithing;
      print "REF $ref\n";
    }
}

my @ppidocproto;
push @ppidocproto, [
		    JoinWithCarriageReturns
		    (
		     Nodes => \@ppicomments,
		     Separator => "\n",
		    ),
		   ];

push @ppidocproto, [
		    JoinWithCarriageReturns
		    (
		     Nodes => [sort {$a->module cmp $b->module} @ppimyuses],
		     Separator => "\n",
		    ),
		   ];

push @ppidocproto, [
		    JoinWithCarriageReturns
		    (
		     Nodes => [sort {$a->module cmp $b->module} @ppinouses],
		     Separator => "\n",
		    ),
		   ];

my $qwstring = 'qw / '.join(" ",sort keys %ppifattributes).' /';
push @ppidocproto, [
		    (
		     bless( {
			     'children' => [
					    bless( {
						    'content' => 'use'
						   }, 'PPI::Token::Word' ),
					    bless( {
						    'content' => ' '
						   }, 'PPI::Token::Whitespace' ),
					    bless( {
						    'content' => 'Class::MethodMaker'
						   }, 'PPI::Token::Word' ),
					    bless( {
						    'content' => '
'
						   }, 'PPI::Token::Whitespace' ),
					    bless( {
						    'content' => '  '
						   }, 'PPI::Token::Whitespace' ),
					    bless( {
						    'content' => 'new_with_init'
						   }, 'PPI::Token::Word' ),
					    bless( {
						    'content' => ' '
						   }, 'PPI::Token::Whitespace' ),
					    bless( {
						    'content' => '=>'
						   }, 'PPI::Token::Operator' ),
					    bless( {
						    'content' => ' '
						   }, 'PPI::Token::Whitespace' ),
					    bless( {
						    'separator' => '\'',
						    'content' => '\'new\''
						   }, 'PPI::Token::Quote::Single' ),
					    bless( {
						    'content' => ','
						   }, 'PPI::Token::Operator' ),
					    bless( {
						    'content' => '
'
						   }, 'PPI::Token::Whitespace' ),
					    bless( {
						    'content' => '  '
						   }, 'PPI::Token::Whitespace' ),
					    bless( {
						    'content' => 'get_set'
						   }, 'PPI::Token::Word' ),
					    bless( {
						    'content' => '       '
						   }, 'PPI::Token::Whitespace' ),
					    bless( {
						    'content' => '=>'
						   }, 'PPI::Token::Operator' ),
					    bless( {
						    'content' => '
'
						   }, 'PPI::Token::Whitespace' ),
					    bless( {
						    'content' => '  '
						   }, 'PPI::Token::Whitespace' ),
					    bless( {
						    'finish' => bless( {
									'content' => ']'
								       }, 'PPI::Token::Structure' ),
						    'children' => [
								   bless( {
									   'content' => '
'
									  }, 'PPI::Token::Whitespace' ),
								   bless( {
									   'content' => '
   '
									  }, 'PPI::Token::Whitespace' ),
								   bless( {
									   'children' => [
											  bless( {
												  'operator' => 'qw',
												  '_sections' => 1,
												  'braced' => 0,
												  'separator' => '/',
												  'content' => $qwstring,
												  'sections' => [
														 {
														  'position' => 4,
														  'type' => '//',
														  'size' => length($qwstring),
														 }
														]
												 }, 'PPI::Token::QuoteLike::Words' )
											 ]
									  }, 'PPI::Statement' ),
								   bless( {
									   'content' => '
'
									  }, 'PPI::Token::Whitespace' ),
								   bless( {
									   'content' => '
  '
									  }, 'PPI::Token::Whitespace' )
								  ],
						    'start' => bless( {
								       'content' => '['
								      }, 'PPI::Token::Structure' )
						   }, 'PPI::Structure::Constructor' ),
					    bless( {
						    'content' => ';'
						   }, 'PPI::Token::Structure' )
					   ]
			    }, 'PPI::Statement::Include' ),
		     bless( {
			     'content' => '
'
			    }, 'PPI::Token::Whitespace' ),
		     bless( {
			     'content' => '
'
			    }, 'PPI::Token::Whitespace' ),
		     bless( {
			     'children' => [
					    bless( {
						    'content' => 'sub'
						   }, 'PPI::Token::Word' ),
					    bless( {
						    'content' => ' '
						   }, 'PPI::Token::Whitespace' ),
					    bless( {
						    'content' => 'init'
						   }, 'PPI::Token::Word' ),
					    bless( {
						    'content' => ' '
						   }, 'PPI::Token::Whitespace' ),
					    bless( {
						    'finish' => bless( {
									'content' => '}'
								       }, 'PPI::Token::Structure' ),
						    'children' => [
								   bless( {
									   'content' => '
'
									  }, 'PPI::Token::Whitespace' ),
								   bless( {
									   'content' => '  '
									  }, 'PPI::Token::Whitespace' ),
								   bless( {
									   'children' => [
											  bless( {
												  'content' => 'my'
												 }, 'PPI::Token::Word' ),
											  bless( {
												  'content' => ' '
												 }, 'PPI::Token::Whitespace' ),
											  bless( {
												  'finish' => bless( {
														      'content' => ')'
														     }, 'PPI::Token::Structure' ),
												  'children' => [
														 bless( {
															 'children' => [
																	bless( {
																		'content' => '$self'
																	       }, 'PPI::Token::Symbol' ),
																	bless( {
																		'content' => ','
																	       }, 'PPI::Token::Operator' ),
																	bless( {
																		'content' => '%args'
																	       }, 'PPI::Token::Symbol' )
																       ]
															}, 'PPI::Statement::Expression' )
														],
												  'start' => bless( {
														     'content' => '('
														    }, 'PPI::Token::Structure' )
												 }, 'PPI::Structure::List' ),
											  bless( {
												  'content' => ' '
												 }, 'PPI::Token::Whitespace' ),
											  bless( {
												  'content' => '='
												 }, 'PPI::Token::Operator' ),
											  bless( {
												  'content' => ' '
												 }, 'PPI::Token::Whitespace' ),
											  bless( {
												  'content' => '@_'
												 }, 'PPI::Token::Magic' ),
											  bless( {
												  'content' => ';'
												 }, 'PPI::Token::Structure' )
											 ]
									  }, 'PPI::Statement::Variable' ),
								   bless( {
									   'content' => '
'
									  }, 'PPI::Token::Whitespace' ),
								   @ppiisubs,
								  ],
						    'start' => bless( {
								       'content' => '{'
								      }, 'PPI::Token::Structure' )
						   }, 'PPI::Structure::Block' )
					   ]
			    }, 'PPI::Statement::Sub' ),
		     bless( {
			     'content' => '
'
			    }, 'PPI::Token::Whitespace' ),
		     bless( {
			     'content' => '
'
			    }, 'PPI::Token::Whitespace' ),
		     bless( {
			     'children' => [
					    bless( {
						    'content' => 'sub'
						   }, 'PPI::Token::Word' ),
					    bless( {
						    'content' => ' '
						   }, 'PPI::Token::Whitespace' ),
					    bless( {
						    'content' => 'Execute'
						   }, 'PPI::Token::Word' ),
					    bless( {
						    'content' => ' '
						   }, 'PPI::Token::Whitespace' ),
					    bless( {
						    'finish' => bless( {
									'content' => '}'
								       }, 'PPI::Token::Structure' ),
						    'children' => [
								   bless( {
									   'content' => '
'
									  }, 'PPI::Token::Whitespace' ),
								   bless( {
									   'content' => '  '
									  }, 'PPI::Token::Whitespace' ),
								   bless( {
									   'children' => [
											  bless( {
												  'content' => 'my'
												 }, 'PPI::Token::Word' ),
											  bless( {
												  'content' => ' '
												 }, 'PPI::Token::Whitespace' ),
											  bless( {
												  'finish' => bless( {
														      'content' => ')'
														     }, 'PPI::Token::Structure' ),
												  'children' => [
														 bless( {
															 'children' => [
																	bless( {
																		'content' => '$self'
																	       }, 'PPI::Token::Symbol' ),
																	bless( {
																		'content' => ','
																	       }, 'PPI::Token::Operator' ),
																	bless( {
																		'content' => '%args'
																	       }, 'PPI::Token::Symbol' )
																       ]
															}, 'PPI::Statement::Expression' )
														],
												  'start' => bless( {
														     'content' => '('
														    }, 'PPI::Token::Structure' )
												 }, 'PPI::Structure::List' ),
											  bless( {
												  'content' => ' '
												 }, 'PPI::Token::Whitespace' ),
											  bless( {
												  'content' => '='
												 }, 'PPI::Token::Operator' ),
											  bless( {
												  'content' => ' '
												 }, 'PPI::Token::Whitespace' ),
											  bless( {
												  'content' => '@_'
												 }, 'PPI::Token::Magic' ),
											  bless( {
												  'content' => ';'
												 }, 'PPI::Token::Structure' )
											 ]
									  }, 'PPI::Statement::Variable' ),
								   bless( {
									   'content' => '
'
									  }, 'PPI::Token::Whitespace' ),
								   @ppinsubsnew,
								  ],
						    'start' => bless( {
								       'content' => '{'
								      }, 'PPI::Token::Structure' )
						   }, 'PPI::Structure::Block' )
					   ]
			    }, 'PPI::Statement::Sub' ),
		    ),
		   ];

push @ppidocproto, [
		    JoinWithCarriageReturns
		    (
		     Nodes => \@ppisubs,
		     Separator => "\n\n",
		    )
		   ];

push @ppidocproto, [
		    bless( {
			   'children' => [
					  bless( {
						  'content' => '1'
						 }, 'PPI::Token::Number' ),
					  bless( {
						  'content' => ';'
						 }, 'PPI::Token::Structure' )
					 ]
			}, 'PPI::Statement' ),
  bless( {
	  'content' => "\n",
	 }, 'PPI::Token::Whitespace' ),
];

# $c =~ s/\@ARGV/\@\{\$args\{Items\}\}/g;
#                                                           bless( {
#                                                                    'content' => '@ARGV'
#                                                                  }, 'PPI::Token::Symbol' ),

#                                                           bless( {
#                                                                    'content' => '$ARGV'
#                                                                  }, 'PPI::Token::Symbol' ),
#                                                           bless( {
#                                                                    'finish' => bless( {
#                                                                                         'content' => ']'
#                                                                                       }, 'PPI::Token::Structure' ),
#                                                                    'children' => [
#                                                                                    bless( {
#                                                                                             'children' => [
#                                                                                                             bless( {
#                                                                                                                      'content' => '0'
#                                                                                                                    }, 'PPI::Token::Number' )
#                                                                                                           ]
#                                                                                           }, 'PPI::Statement::Expression' )
#                                                                                  ],
#                                                                    'start' => bless( {
#                                                                                        'content' => '['
#                                                                                      }, 'PPI::Token::Structure' )
#                                                                  }, 'PPI::Structure::Subscript' ),

unshift @ppidocproto, [
		       bless( {
			       'children' => [
					      bless( {
						      'content' => 'package'
						     }, 'PPI::Token::Word' ),
					      bless( {
						      'content' => ' '
						     }, 'PPI::Token::Whitespace' ),
					      bless( {
						      'content' => $pkgname,
						     }, 'PPI::Token::Word' ),
					      bless( {
						      'content' => ';'
						     }, 'PPI::Token::Structure' )
					     ]
			      }, 'PPI::Statement::Package' ),
		      ];

my @ppidocument = JoinWithCarriageReturns
  (
   Nodes => \@ppidocproto,
   Separator => "\n\n",
  );

my $document = bless({'children' => \@ppidocument}, 'PPI::Document');

# print Dumper($document);

foreach my $name (keys %$ppisubsh) {
  ConvertSubCalls
    (
     Name => $name,
     Node => $document,
    );
}

foreach my $name (keys %ppiattreplace) {
  ConvertToAttributes
    (
     Name => $name,
     Node => $document,
    );
}

my $fh = IO::File->new();
$fh->open(">$of") or die "cannot open outfile <$of>\n";
print $fh NodeSerialize(Node => $document);
# print $fh $c;
$fh->close;

my $last = $pkgname;
$last =~ s/.*:://;
my $name = lc($last);
my $c = join("\n",
	     (
	      "#!/usr/bin/perl -w",
	      "",
	      "use $pkgname;",
	      "",
	      "my \$$name = $pkgname->new();",
	      "\$$name->Execute(Items => \\\@ARGV);"
	     ));
print $c."\n";

sub ProcessVariables {
  my %args = @_;
  # print Dumper(\%args);
  # extract out the lhs and rhs
  # get the variables
  my @lhss = $args{Node}->variables;
  my $cnt = scalar @lhss;
  # now for the symbols
  my @tmp;
  my @rhss;
  my $inrhs = 0;
  foreach my $subnode ($args{Node}->children) {
			     if ($inrhs) {
			     push @tmp, $subnode;
			    }
		       if ($subnode->isa('PPI::Token::Operator') and $subnode->content eq "=") {
			   $inrhs = 1;
			 }
		     }
  my $ref = ref $tmp[0];
  if ($ref !~ /^PPI::/) {
    print "ERROR\n";
    return;
  }
  if ($tmp[0]->isa('PPI::Token::Whitespace')) {
	   shift @tmp;
	 }
      if ($tmp[-1]->isa('PPI::Token::Structure') and $tmp[-1]->content eq ";") {
	  pop @tmp;
	}
      if ($tmp[-1]->isa('PPI::Token::Whitespace')) {
	  pop @tmp;
	}
      # go ahead and get this
      if ((scalar @tmp) != 1) {
	  push @rhss, \@tmp;
	}
      if ($tmp[0]->isa('PPI::Structure::List')) {
	  # print Dumper([$tmp[0]->children]);
	  if (scalar $tmp[0]->children and [$tmp[0]->children]->[0]->isa('PPI::Statement')) {
	  my @list;
	  my $i = 1;
	  foreach my $subnode ([$tmp[0]->children]->[0]->children) {
	  if ($subnode->isa('PPI::Token::Whitespace')) {

	} elsif ($subnode->isa('PPI::Token::Operator') and $subnode->content eq ',') {
		 my @copy = @list;
		 push @rhss, \@copy;
		 @list = ();
	       } elsif ($subnode->isa('PPI::Token::Magic') and $subnode->content eq '@_') {
			for my $i (1..($cnt - $i)) {
			push @rhss,  bless( { 'content' => 'shift' }, 'PPI::Token::Symbol' );
		      }
      push @rhss,  bless( { 'content' => '@_' }, 'PPI::Token::Magic' );
		       } else {
			 push @list, $subnode;
		       }
      ++$i;
    }
  if (scalar @list) {
    push @rhss, \@list;
  }
}
} elsif ($tmp[0]->isa('PPI::Token::Magic') and $tmp[0]->content eq '@_') {
  for my $i (1..($cnt - 1)) {
    push @rhss,  bless( { 'content' => 'shift' }, 'PPI::Token::Symbol' );
			}
			push @rhss,  bless( { 'content' => '@_' }, 'PPI::Token::Magic' );
					 }
			return {
				Success => 1,
				Result => {
					   RHSs => \@rhss,
					   LHSs => \@lhss,
					  },
			       };
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
  # return $args{Name};
  my $ret = $camelcase->GetBestCamelCase
    (Word => $args{Name});
  # my $ret = undef;
  # print Dumper({RET => $ret});
  return $ret || $args{Name};

  #   my $res = `/var/lib/myfrdcsa/codebases/internal/code-monkey/scripts/best-breakdown-camelcase.pl $args{Name}`;
  #   my @newvalues = split /\n/, $res;
  #   shift @newvalues;
  #   shift @newvalues;
  #   return shift @newvalues;
}

sub JoinWithCarriageReturns {
  my %args = @_;
  my @list;
  foreach my $node (@{$args{Nodes}}) {
    push @list, bless( { 'content' => $args{Separator} }, 'PPI::Token::Whitespace' ) if scalar @list;
    my $ref = ref $node;
    if ($ref eq "ARRAY") {
      push @list, @$node;
    } else {
      push @list, $node;
    }
  }
  return @list;
}

sub NodeSerialize {
  my (%args) = @_;
  my $doc = PPI::Document->new();
  $doc->add_element(GetCopy(Node => $args{Node}));
  return $doc->serialize;
}

sub StringParse {
  my (%args) = @_;
  my $string = $args{String};
  my $doc = PPI::Document->new(\$string);
  return $doc;
}

sub GetCopy {
  my (%args) = @_;
  my $VAR1 = undef;
  eval Dumper($args{Node});
  return $VAR1;
}

sub Util {
  # $dumper->print;
  # my $res = $module->normalized;
  # print $res->{Document}->serialize."\n";
  # print Dumper([keys %$res]);
  # print $res->serialize;
  # print $module->serialize;
}

sub SpliceChildren {
  my (%args) = @_;
  # array bounds checking
  my $node = $args{Node};
  if ($node->isa("PPI::Node")) {
    # now we have to remove the subnodes from the occuring including and
    # after the position, then add the children, then readd the subnodes
    my @children = $node->children;
    splice @children,$args{Offset},$args{Length},@{$args{Children}};
    $node->{children} = \@children;
  } else {
    print "ERROR, not a PPI::Node\n";
  }
}

sub ConvertSubCalls {
  my %args = @_;
  my $i = 0;
  foreach my $child ($args{Node}->children) {
    if ($child->isa('PPI::Node')) {
      ConvertSubCalls
	(
	 Node => $child,
	 Name => $args{Name},
	);
    } elsif ($child->isa('PPI::Element')) {
      if ($child->isa('PPI::Token::Word')) {
	if ($child->literal eq $args{Name}) {
	  if (! $args{Node}->isa('PPI::Statement::Sub')) {
	    print "adding \$self->".$child->literal."\n";
	    SpliceChildren
	      (
	       Node => $args{Node},
	       Offset => $i,
	       Length => 0,
	       Children => [
			    bless( {
				    'content' => '$self'
				   }, 'PPI::Token::Symbol' ),
			    bless( {
				    'content' => '->'
				   }, 'PPI::Token::Operator' ),
			   ],
	      );
	  }
	}
      } else {
	my $ref = ref $child;
	# print "REF2 $ref\n";
      }
    } else {
      my $ref = ref $child;
      # print "REF1 $ref\n";
    }
    ++$i;
  }
}

sub ConvertToAttributes {
  my %args = @_;

  # be sure to add checks to strings

  # if it's a single or double quote, use the "... ".$self->Thing."
  # ..."

  # if it's a back tick `, create a var: my $thing = $self->Thing; in
  # the statement prior to it.  check if it works, as there might be
  # things that modify the $self-> in the current line or statement
  # before it's use in the backtick thing

  my $i = 0;
  foreach my $child ($args{Node}->children) {
    if ($child->isa('PPI::Node')) {
      ConvertToAttributes
	(
	 Node => $child,
	 Name => $args{Name},
	);
    } elsif ($child->isa('PPI::Element')) {
      if ($child->isa('PPI::Token::Symbol')) {
	if ($child->symbol eq $args{Name}) {
	  print "adding \$self->".$ppiattreplace{$args{Name}}."\n";
	  my $toinsert =
	    [
	     bless( {
		     'content' => '$self'
		    }, 'PPI::Token::Symbol' ),
	     bless( {
		     'content' => '->'
		    }, 'PPI::Token::Operator' ),
	     bless( {
		     'content' => $ppiattreplace{$args{Name}},
		    }, 'PPI::Token::Symbol' ),
	    ];
	  my $toinsert2;
	  if ($i > 0) {
	    my $child2 = [$args{Node}->children]->[$i - 1];
	    if ($child2->isa('PPI::Token::Cast') and
		$child2->content =~ /(@|%|&|\*)/) {
	      $toinsert2 =
		[
		 bless( {
			 'finish' => bless( {
					     'content' => '}'
					    }, 'PPI::Token::Structure' ),
			 'children' => [
					bless( {
						'children' => $toinsert,
					       }, 'PPI::Statement' )
				       ],
			 'start' => bless( {
					    'content' => '{'
					   }, 'PPI::Token::Structure' )
			}, 'PPI::Structure::Block' )
		];
	    }
	  }
	  if (! defined $toinsert2) {
	    $toinsert2 = $toinsert;
	  }
	  SpliceChildren
	    (
	     Node => $args{Node},
	     Offset => $i,
	     Length => 1,
	     Children => $toinsert2,
	    );
	}
      } else {
	my $ref = ref $child;
	# print "REF2 $ref\n";
      }
    } else {
      my $ref = ref $child;
      # print "REF1 $ref\n";
    }
    ++$i;
  }
}

# ppi-convert-script-to-module.pl -i /usr/bin/radar-web-search -o /tmp/WebSearch.pm -m RADAR::Method::WebSearch
# Can't call method "isa" on an undefined value at /var/lib/myfrdcsa/codebases/internal/code-monkey/scripts/ppi-convert-script-to-module.pl line 733.

# my $self->Res;

# my @dirs = ("/home/andrewdo/Downloads","/home/andrewdo/Media/Incoming/software");
#  became
# $self->Dirs("/home/andrewdo/Downloads");
