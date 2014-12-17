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
my $outputfna_clean=$ARGV[0] . "/" . $jobname . "_output_clean.fna";
my $outputfna_contam=$ARGV[0] . "/" . $jobname . "_output_contam.fna";
my $cleancontigs=$ARGV[0] . "/" . $jobname . "_Intermediate/" . $jobname . "_kmer_clean_contigs";

my %clean;
open(IN,$cleancontigs) or die "$cleancontigs does not exist.  Failure of kmer algorithm.\n";
while(my $line=<IN>){
	chomp($line);
	$clean{$line}=1;
}
close(IN);

my $out_clean=Bio::SeqIO->new(-file => ">$outputfna_clean",-format => 'Fasta');
my $out_contam=Bio::SeqIO->new(-file => ">$outputfna_contam",-format => 'Fasta');
my $in=Bio::SeqIO->new(-file => "$inputfna" ,  -format => 'Fasta');
while (my $seqobj=$in->next_seq()) {
	if(exists($clean{$seqobj->display_id()})){
    		$out_clean->write_seq($seqobj);
	}
	else{
		$out_contam->write_seq($seqobj);
	}
}


1;
