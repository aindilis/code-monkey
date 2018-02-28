#!/usr/bin/perl -w

use Data::Dumper;

# extract some features and use these to generate a specification string

$specification = "
	-c			Clean
	-b			Send bulk
	-B			Send not bulk
	-r <receiver>		Receiver
	-t <type>		Type (mbox or trec)
	-n <number>		Number of messages
	--auto			Approve all messages
	--results		Return results
	-g			Generate new headers
	--single		Send single test mail
	--test			Send multiple test mails
	--update		Update SARE rules
	-a			Analyze Log Files
	-o			Optimize Performance
	-e			Edit new spam rules
	-d			Edit distributed cluster configuration files and restart services
	--train <corpus>	Train bayes database

	-u [<host> <port>]	Run as a UniLang agent

	-w			Require user input before exiting
";

my $entries = {};
my $i = 0;
foreach my $line (split /\n/, $specification) {
  # extract current mappings
  if ($line =~ /^\t+([^\t]+)\t+(.*)$/) {
    my $a1 = $1;
    my $a2 = $2;
    my $res = "";
    if ($a1 =~ /^(.*)\s(.+)$/) {
      $a1 = $1;
      $res = $2;
    }
    $entries->{$a1}->{$a2} = {Filler => $res, Order => $i};
  }
  ++$i;
}
foreach my $entry (keys %$entries) {
  if (scalar keys %{$entries->{$entry}} > 1) {
    print Dumper($entry => $entries->{$entry});
  }
}

