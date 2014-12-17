#!/usr/bin/env perl
#ProDeGe Copyright (c) 2014, The Regents of the University of California,
#through Lawrence Berkeley National Laboratory (subject to receipt of any
#required approvals from the U.S. Dept. of Energy).  All rights reserved.

use strict;
use warnings;
use Bio::SeqIO;

my $usage="$0 <directory which contains input fasta file> <jobname>\n";
unless(@ARGV==2) {print $usage;exit(1);}
my $jobname=$ARGV[1];
my $inputfna=$ARGV[0] . "/" . $jobname . "_input.fna";
my $log=$ARGV[0] . "/" . $jobname . "_log";

my $tot_size=0;
my $in=Bio::SeqIO->new(-file => "$inputfna" ,  -format => 'Fasta');
while (my $seqobj=$in->next_seq()) {
	$tot_size=$seqobj->length+$tot_size;
}
if($tot_size<250000){
	open(OUT,">>$log");
	print OUT "Total sequence size is $tot_size.  Results may not be valid.\n";
	close(OUT);
}	
1;
