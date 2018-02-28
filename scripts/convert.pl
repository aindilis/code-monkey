#!/usr/bin/perl -w

use Data::Dumper;

sub ChangeVariablesIntoAttributes {
  my $contents = shift;
  my @endresult;
  @items = qw ( publicdb privatedb permanentdb testingdb safeversion );
  foreach my $line (split /\n/,$contents) {
    foreach my $i1 (@items) {
      my $u1 = Proper($i1);
      my $l1 = lc($i1);
      my $r1 = '\$'.$l1.'\s=\s(.*?);$';
      if ($line =~ /$r1/) {
	# print "$r1\n";
	my $pot = $1;
	foreach my $i2 (@items) {
	  my $u2 = Proper($i2);
	  my $l2 = lc($i2);
	  my $r2 = '\$'.$l2.'\b';
	  # print "$r2\n";
	  $pot =~ s/$r2/\"\.\$self->$u2\.\"/g;
	}
	$line = '$self->'.$u1."($pot);";
      }
    }
    $line =~ s/""\.//g;
    $line =~ s/\.""//g;
    push @endresult, $line;
  }
  return join("\n",@endresult);
}

sub Proper {
  # first split into longest words
  return ucfirst (lc shift);
}

sub ExportAllFunction {
  my $contents = shift;
  my @subnames = $contents =~ /^sub (\S+) .*/mg;
  my @lines = split /\n/,$contents;
  my @newlines = (splice(@lines,0,2),
		  "require Exporter;",
		  "\@ISA = qw(Exporter);",
		  "\@EXPORT = qw (".join(" ",@subnames).");",
		  "",
		  @lines);
  return join("\n",@newlines);
}

sub ChangeVariablesIntoUniversal {
  my $contents = shift;
  my @endresult;
  @items = qw ( client clientin prompt );
  foreach my $line (split /\n/,$contents) {
    foreach my $i1 (@items) {
      my $u1 = Proper($i1);
      my $l1 = lc($i1);
      my $r1 = '\$'.$l1.'\s=\s(.*?);$';
      if ($line =~ /$r1/) {
	# print "$r1\n";
	my $pot = $1;
	foreach my $i2 (@items) {
	  my $u2 = Proper($i2);
	  my $l2 = lc($i2);
	  my $r2 = '\$'.$l2.'\b';
	  # print "$r2\n";
	  $pot =~ s/$r2/\"\.\$self->$u2\.\"/g;
	}
	$line = '$self->'.$u1."($pot);";
      }
    }
    $line =~ s/""\.//g;
    $line =~ s/\.""//g;
    push @endresult, $line;
  }
  return join("\n",@endresult);
}


sub Update {
  my $OUT;
  my $file = $ARGV[0];
  my $contents = `cat $file`;
  # $contents = ChangeVariablesIntoAttributes($contents);
  $contents = ExportAllFunction($contents);
  open(OUT,">/tmp/out");
  print OUT $contents;
  close(OUT);
  system "perltidy /tmp/out";
  $contents = `cat /tmp/out.tdy`;
  print $contents;
}

Update;
