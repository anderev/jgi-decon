#!/usr/bin/env perl

use strict;
use warnings;
use Bio::SeqIO;

my $usage="$0 <directory which contains input fasta file> <jobname>\n";
unless(@ARGV==2) {print $usage;exit(1);}
my $jobname=$ARGV[1];
my $inputfna=$ARGV[0] . "/" . $jobname . "_input.fna";
my $outputfna=$ARGV[0] . "/" . $jobname . "_output_clean.fna";
my $cleancontigs=$ARGV[0] . "/" . $jobname . "_Intermediate/" . $jobname . "_kmer_clean_contigs";

my %clean;
open(IN,$cleancontigs) or die "$cleancontigs does not exist.  Failure of kmer algorithm.\n";
while(my $line=<IN>){
	chomp($line);
	$clean{$line}=1;
}
close(IN);

my $out=Bio::SeqIO->new(-file => ">$outputfna",-format => 'Fasta');
my $in=Bio::SeqIO->new(-file => "$inputfna" ,  -format => 'Fasta');
while (my $seqobj=$in->next_seq()) {
	if(exists($clean{$seqobj->display_id()})){
    		$out->write_seq($seqobj);
	}
}

$outputfna=$ARGV[0] . "/" . $jobname . "_output_contam.fna";
my $contamcontigs=$ARGV[0] . "/" . $jobname . "_Intermediate/" . $jobname . "_kmer_contam_contigs";

my %contam;
open(IN,$contamcontigs) or die "$contamcontigs does not exist.  Failure of kmer algorithm.\n";
while(my $line=<IN>){
        chomp($line);
        $contam{$line}=1;
}
close(IN);

$out=Bio::SeqIO->new(-file => ">$outputfna",-format => 'Fasta');
$in=Bio::SeqIO->new(-file => "$inputfna" ,  -format => 'Fasta');
while (my $seqobj=$in->next_seq()) {
        if(exists($contam{$seqobj->display_id()})){
                $out->write_seq($seqobj);
        }
}

1;
