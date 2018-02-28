#!/usr/bin/perl -w

# parse with PPI

use BOSS::Config;

use Data::Dumper;
use File::Slurp;
# use Perl::Critic;
use PPI::Document;

$specification = q(
	-f <file>	File to suggest refactorings
);

my $config =
  BOSS::Config->new
  (Spec => $specification);
my $conf = $config->CLIConfig;

my $text = read_file($conf->{-f});
my $doc = PPI::Document->new
  (
   \$text,
  );

# here are the different tests that we can do

my $tests =
  {
   "Ensure scripts have comments comprising documentation" =>
   {
    Test => sub {
      my %args = @_;
      # extract all comments
      my $comments = $args{Document}->find('PPI::Token::Comment');
      print Dumper($comments);
      return {
	      ActionSuggested => "Write comments that document the program",
	      ActionSub => sub {
		require Manager::Dialog qw(QueryUser);
		my $comments = QueryUser("What does this program do?");
		# insert into the document
	      },
	      Success => 1,
	     };
    },
   },
  };

foreach my $test (sort keys %$tests) {
  # check whether the item needs this particular test
  my $res = $tests->{$test}->{Test}->
    (
     Document => $doc,
     Text => $text,
    );
}
