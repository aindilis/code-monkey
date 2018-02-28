#!/usr/bin/perl -w

my $data = `cat /var/lib/myfrdcsa/codebases/internal/code-monkey/data/results.pl`;
my $VAR1;
eval $data;
$res = $VAR1;
$VAR1 = undef;

print join("\n\n---------------------------------\n\n",sort keys %{$res->{$ARGV[0]}})."\n";
