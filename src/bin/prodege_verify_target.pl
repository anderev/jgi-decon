#!/usr/bin/env perl
#ProDeGe Copyright (c) 2014, The Regents of the University of California,
#through Lawrence Berkeley National Laboratory (subject to receipt of any
#required approvals from the U.S. Dept. of Energy).  All rights reserved.

use strict;
use warnings;

unless(@ARGV==3){print "Usage: $0 <working dir> <IMG taxonomy file> <jobname>\n"; exit;}
my $wdir=$ARGV[0];
my $taxfile=$ARGV[1];
my $jobname=$ARGV[2];
my $targetfile=$wdir . "/" . $jobname . "_Intermediate/" . $jobname . "_target";

open(IN,$targetfile) or die "$targetfile does not exist\n";
my $known_target=<IN>;
close(IN);
chomp($known_target);
#$known_target=~s/Actinobacteridae/Actinobacteria/;#add for issue10
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
open(OUT,">>$wdir" . "/" . $jobname . "_log");
if($known_target=~/^$/){
        print OUT "Input target is empty. Must skip blast binning.\n";
        $cmd="rm $targetfile";
        system($cmd);
}
elsif(scalar(@nts)>0){
	$known_target=~s/Actinobacteria\tActinobacteria/Actinobacteria/;#add for issue10
	$known_target=~s/\t/;/g;
	print OUT "Input target $known_target has been verified.\n";
	open(OUT2,">$targetfile");
	print OUT2 $known_target . "\n";
	close(OUT2);
}
else{
	print OUT "Input target $known_target does not exist in $taxfile. Must skip blast binning.\n";
	$cmd="rm $targetfile";
	system($cmd);
}
close(OUT);
