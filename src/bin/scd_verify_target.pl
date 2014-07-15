#!/usr/bin/env perl

use strict;
use warnings;

unless(@ARGV==3){print "Usage: $0 <working dir> <NCBI tax file> <jobname>\n"; exit;}
my $wdir=$ARGV[0];
my $taxfile=$ARGV[1];
my $jobname=$ARGV[2];
my $targetfile=$wdir . "/" . $jobname . "_Intermediate/" . $jobname . "_target";

open(IN,$targetfile) or die "$targetfile does not exist\n";
my $known_target=<IN>;
close(IN);
chomp($known_target);
$known_target=~s/;;;;;;;/;/g;
$known_target=~s/;;;;;;/;/g;
$known_target=~s/;;;;;/;/g;
$known_target=~s/;;;;/;/g;
$known_target=~s/;;;/;/g;
$known_target=~s/;;/;/g;
$known_target=~s/;/\t/g;
$known_target=~s/\t$//g;
my $cmd="grep -m 1 " . "\"" . $known_target . "\" $taxfile";
my @nts=`$cmd`;
if(scalar(@nts)>0){
	$known_target=~s/\t/;/g;
	open(OUT,">$targetfile");
	print OUT $known_target . "\n";
	close(OUT);
}
else{
	open(OUT,">>$wdir" . "/" . $jobname . "_log");
	print OUT "$known_target does not exist in $taxfile.\n";
	close(OUT);
	$cmd="rm $targetfile";
	system($cmd);
}

