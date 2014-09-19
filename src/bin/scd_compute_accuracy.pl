#!/usr/bin/env perl

use strict;
use warnings;

unless(@ARGV>1){ print "Usage: $0 <directory of fasta file> <jobname>\n"; exit;}
my $dir=$ARGV[0];
my $jobname=$ARGV[1];

my $kmerclean=$dir . "/" . $jobname . "_Intermediate/" . $jobname . "_kmer_clean_contigs";
my $kmercontam=$dir . "/" . $jobname . "_Intermediate/" . $jobname . "_kmer_contam_contigs";
my $blastclean=$dir . "/" . $jobname . "_Intermediate/" . $jobname . "_blast_clean_contigs";
my $blastcontam=$dir . "/" . $jobname . "_Intermediate/" . $jobname . "_blast_contam_contigs";
my $log=$dir . "/" . $jobname . "_accuracy";

my $tp=0;my $tn=0;my $fp=0;my $fn=0;
my $ntp=0;my $ntn=0;my $nfp=0;my $nfn=0;
open(IN,$kmerclean) or die "$kmerclean can not be opened.";
while(my $line=<IN>){
	chomp($line);
        my @arr=split(/_/,$line);
        my $len=pop(@arr);
	if($line=~/clean/){
		$tp++;
		$ntp=$ntp+$len;
        }elsif($line=~/contam/){
                $fp++;
		$nfp=$nfp+$len;
	}
}
close(IN);
open(IN,$kmercontam);
while(my $line=<IN>){
        chomp($line);
        my @arr=split(/_/,$line);
        my $len=pop(@arr);
        if($line=~/clean/){
                $fn++;  
		$nfn=$nfn+$len;
        }elsif($line=~/contam/){
                $tn++;
		$ntn=$ntn+$len;
        }       
}
close(IN);

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
 
my $txt="";
open(OUT,">>$log");
print OUT "$txt\t";
print OUT "$jobname\t";
print OUT $tp+$tn+$fp+$fn . "\t";
print OUT $tp+$fn . "\t";
print OUT $tn+$fp;
print OUT "\t" . $bc . "\t" . $bm;
print OUT "\t$tp\t$tn\t$fn\t$fp\t";
if(($tp+$fn)>0){print OUT sprintf("%.2f",$tp/($tp+$fn)) . "\t";}else{print OUT "NA\t";}
if(($fp+$tn)>0){print OUT sprintf("%.2f",$tn/($tn+$fp)) . "\t";}else{print OUT "NA\t";}
print OUT $ntp+$ntn+$nfp+$nfn . "\t";
print OUT $ntp+$nfn . "\t";
print OUT $ntn+$nfp;
print OUT "\t$ntp\t$ntn\t$nfn\t$nfp\t";
if(($ntp+$nfn)>0){print OUT sprintf("%.2f",$ntp/($ntp+$nfn)) . "\t";}else{print OUT "NA\t";}
if(($nfp+$ntn)>0){print OUT sprintf("%.2f",$ntn/($ntn+$nfp)) . "\n";}else{print OUT "NA\n";}
close(OUT);
#my $cmd="tail -1 $log >> $txt";
#system($cmd);
1;


