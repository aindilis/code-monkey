#!/usr/bin/perl -w

use PerlLib::EasyPersist;
use PerlLib::SwissArmyKnife;

use Data::Dumper;

my $persist = PerlLib::EasyPersist->new;

my $modules = {};

sub LoadFRDCSAModules {
  my %args = @_;
  my $res = $persist->Get
    (
     Command => '`boss list_modules`',
    );
  if ($res->{Success}) {
    foreach my $module (split /\n/, $res->{Result}) {
      $module =~ s/\.pm$//;
      $module =~ s/\//::/;
      $modules->{$module}++;
    }
    # print Dumper($modules);
  }
}

sub ProcessTmon {
  my %args = @_;
  if (! -f $args{Tmon}) {
    warn "No such file ".$args{Tmon}."\n";
    return;
  }
  my $c = read_file($args{Tmon});
  foreach my $line (split /\n/, $c) {
    if ($line =~ /^\& (\d+) (.+)\s+(.+)$/) {
      my $id = $1;
      my $module = $2;
      my $function = $3;
      my $accept = 0;
      if (! scalar keys %{$args{Filters}}) {
	$accept = 1;
      } else {
	if (exists $args{Filters}->{"Main"}) {
	  if ($module eq "main") {
	    $accept = 1;
	  }
	}
	if (exists $args{Filters}->{"FRDCSA"}) {
	  if (exists $modules->{$module}) {
	    $accept = 1;
	  }
	}
      }
      if ($accept) {
	print "$module $function\n";
      }
    }
  }
}

LoadFRDCSAModules();

ProcessTmon
  (
   Tmon => "tmon.out",
   Filters => {
	       # "FRDCSA" => 1,
	       "Main" => 1,
	      },
  );
