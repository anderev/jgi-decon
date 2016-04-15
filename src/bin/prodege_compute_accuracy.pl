#!/usr/bin/env perl
#ProDeGe Copyright (c) 2014, The Regents of the University of California,
#through Lawrence Berkeley National Laboratory (subject to receipt of any
#required approvals from the U.S. Dept. of Energy).  All rights reserved.

use strict;
use warnings;
use Bio::SeqIO;

unless(@ARGV>1){ print "Usage: $0 <directory of fasta file> <jobname>\n"; exit;}
my $dir=$ARGV[0];
my $jobname=$ARGV[1];
my $int_dir=$dir . "/" . $jobname . "_Intermediate/";
#my $kmerclean=$int_dir . $jobname . "_kmer_clean_contigs";
#my $kmercontam=$int_dir . $jobname . "_kmer_contam_contigs";
my $blastclean=$int_dir . $jobname . "_blast_clean_contigs";
my $blastcontam=$int_dir . $jobname . "_blast_contam_contigs";
my $outclean=$dir . "/" . $jobname . "_output_clean.fna";
my $outcontam=$dir . "/" . $jobname . "_output_contam.fna";

my $log=$dir . "/" . $jobname . "_accuracy";

my $realclean=0;
my $realcontam=0;
open(IN,$dir . "/" . $jobname . "_input.fna");
while(my $line=<IN>){
	if($line=~/^>/){
		if($line=~/clean/){
			$realclean++;
		}
		else{
			$realcontam++;
		}
	}
}
close(IN);

my $tp=0;my $tn=0;my $fp=0;my $fn=0;
my $ntp=0;my $ntn=0;my $nfp=0;my $nfn=0;
my $totclean=0;my $ntotclean=0;my $totcontam=0;my $ntotcontam=0;
my $in=Bio::SeqIO->new(-file => "$outclean" ,  -format => 'Fasta');
while (my $seqobj=$in->next_seq()){
	if($seqobj->display_id()=~/clean/){
		$tp++;
		$ntp=$ntp+$seqobj->length;
        }
	elsif($seqobj->display_id()=~/contam/){
                $fp++;
		$nfp=$nfp+$seqobj->length;
	}
	else{
		$totclean++;
		$ntotclean=$ntotclean+$seqobj->length;
	}
}
my $in2=Bio::SeqIO->new(-file => "$outcontam" ,  -format => 'Fasta');
while (my $seqobj2=$in2->next_seq()){
        if($seqobj2->display_id()=~/clean/){
                $fn++;  
                $nfn=$nfn+$seqobj2->length;
        }
        elsif($seqobj2->display_id()=~/contam/){
                $tn++;
                $ntn=$ntn+$seqobj2->length;
        }
        else{
                $totcontam++;
                $ntotcontam=$ntotcontam+$seqobj2->length;
        }
}

my $bc=0;
my $bm=0;
if(-e $blastclean){
	open(IN,$blastclean);
	while(my $line=<IN>){
        	$bc++;
	}
	close(IN);
}
if(-e $blastcontam){
	open(IN,$blastcontam);
	while(my $line=<IN>){
		$bm++;
	}
	close(IN);
}
 
my $txt="prodege2.3";
open(OUT,">>$log");
if($tp+$tn+$fp+$fn != $realclean+$realcontam){
	print OUT "Error in accuracy computation\n";
} 
print OUT "$txt\t";
print OUT "$jobname\t";
#print OUT $tp+$tn+$fp+$fn . "\t";
#print OUT $tp+$fn . "\t";
#print OUT $tn+$fp;
print OUT $realclean+$realcontam . "\t";
print OUT $realclean . "\t";
print OUT $realcontam ;
print OUT "\t" . $bc . "\t" . $bm;
print OUT "\t$tp\t$tn\t$fn\t$fp\t";
if(($tp+$fn)>0){print OUT sprintf("%.2f",$tp/($tp+$fn)) . "\t";}else{print OUT "NA\t";}
if(($fp+$tn)>0){print OUT sprintf("%.2f",$tn/($tn+$fp)) . "\t";}else{print OUT "NA\t";}
print OUT $ntp+$ntn+$nfp+$nfn . "\t";
print OUT $ntp+$nfn . "\t";
print OUT $ntn+$nfp;
print OUT "\t$ntp\t$ntn\t$nfn\t$nfp\t";
if(($ntp+$nfn)>0){print OUT sprintf("%.2f",$ntp/($ntp+$nfn)) . "\t";}else{print OUT "NA\t";}
if(($nfp+$ntn)>0){print OUT sprintf("%.2f",$ntn/($ntn+$nfp)) . "\t";}else{print OUT "NA\t";}
if(($ntp+$ntn+$nfn+$nfp)!=0){print OUT sprintf("%.2f",($ntp+$ntn)/($ntp+$ntn+$nfn+$nfp)) . "\n";}else{print OUT "NA\t";}
close(OUT);
#my $cmd="tail -1 $log >> $txt";
#system($cmd);
1;
