#!/usr/bin/env perl
#ProDeGe Copyright (c) 2014, The Regents of the University of California,
#through Lawrence Berkeley National Laboratory (subject to receipt of any
#required approvals from the U.S. Dept. of Energy).  All rights reserved.

use strict;
use warnings;

my $usage="$0 <directory which contains input fasta file> <bin dir> <job name>\n";
@ARGV==4 or die $usage;
my $RCmd = defined $ENV{R_EXE} ? $ENV{R_EXE} : 'R';
my $wdir=$ARGV[0];
my $bin=$ARGV[1];
my $lib=$ARGV[1] . "/../lib/";
my $jobname=$ARGV[2];
my $kcutoff=$ARGV[3];
my $fbin_target=$wdir . "/" . $jobname . "_Intermediate/" . $jobname . "_binning_target";
my $log=$wdir . "/" . $jobname . "_log";
open(LOG,">>$log");

my %targets;
my %checkclean;

if(-e $fbin_target){
  open(IN,$fbin_target) or die;
  my $line=<IN>;
  chomp($line);
  my @arr=split(/\t/,$line);
  my $bin_target=$arr[3];
  close(IN);

  my %cl;
  my @counts=(0,0,0);
  my $contigLCA=$wdir . "/" . $jobname . "_Intermediate/" . $jobname . "_contigs.LCA"; 
  my $blast_clean=$wdir . "/" . $jobname . "_Intermediate/" . $jobname . "_blast_clean_contigs";
  my $blast_contam=$wdir . "/" . $jobname . "_Intermediate/" . $jobname . "_blast_contam_contigs";
  my $blast_undecided=$wdir . "/" . $jobname . "_Intermediate/" . $jobname . "_blast_undecided_contigs";
  my $species_file=$wdir . "/" . $jobname . "_Intermediate/" . $jobname . "_contigs.species";
  my $kmer_clean=$wdir . "/" . $jobname . "_Intermediate/" . $jobname . "_kmer_clean_contigs";
  my $kmer_contam=$wdir . "/" . $jobname . "_Intermediate/" . $jobname . "_kmer_contam_contigs";

  my %species;
  open(IN,$species_file) or die;
  while(my $line=<IN>){
	chomp($line);
	my @arr=split(/,/,$line);
	$species{$arr[0]}=$line;
  }
  close(IN);
  
  open(IN,$contigLCA) or die;
  open(OUTC,">$blast_clean");
  open(OUTD,">$blast_contam");
  open(OUTU,">$blast_undecided");
  while(my $line=<IN>){
	chomp($line);
        my @arr=split(/\t/,$line);
        if(defined($arr[1])){
        	$arr[1]=~s/^ //;
		$cl{$arr[0]}=$arr[1];
		if($arr[1]=~/$bin_target/){
			print OUTC "$arr[0]\n";
                	$counts[0]++; #clean
			$checkclean{$arr[0]}=1;
		}
                elsif($bin_target=~/$arr[1]/){
                        if($species{$arr[0]}=~/$bin_target/){
				my $c=()=$species{$arr[0]}=~/$bin_target/g;
				my $g=()=$species{$arr[0]}=~/,/g;
				if($g==0){
                                	print OUTU "$arr[0]\n";
                                        $counts[1]++; #undecided
				}
				elsif($g<=20){
					if($c/$g>=.1){
                        			print OUTC "$arr[0]\n";
						print LOG "$arr[0] <=20 now clean\n";
                        			$counts[0]++; #clean
						$checkclean{$arr[0]}=1;
					}
					else{
						print OUTU "$arr[0]\n";
                                                print LOG "$arr[0] <=20 still undecided\n";
						$counts[1]++; #undecided
					}
				}
				else{
                                       if($c/$g>=.5){
                                                print OUTC "$arr[0]\n";
                                                print LOG "$arr[0] >20 now clean\n";
                                                $counts[0]++; #clean
						$checkclean{$arr[0]}=1;
                                        }
                                        else{
                                                print OUTU "$arr[0]\n";
                                                print LOG "$arr[0] >20 still undecided\n";
                                                $counts[1]++; #undecided
                                        }
				}
			}
			else{
                                print OUTU "$arr[0]\n";
                                $counts[1]++; #undecided
			}
                }
                else{
			print OUTD "$arr[0]\n";
			$counts[2]++; #contam
                }
        }
	else{
 		print OUTU "$arr[0]\n";
        	$counts[1]++; #undecided
	}
  }
  close(IN);
  close(OUTC);
  close(OUTD);
  close(OUTU);

  my $targetfile=$ARGV[0] . "/" . $jobname . "_Intermediate/" . $jobname . "_target";
  open(IN,$targetfile);
  my $known_target=<IN>;
  close(IN);
  chomp($known_target);

  my $cmd;
#  if($counts[1]==0){
#        print LOG "$0: Undecided bin is empty.  No need to perform k-mer analysis.\n";
#	$cmd="cp $blast_clean $wdir/" . $jobname . "_Intermediate/" . $jobname . "_kmer_clean_contigs; cp $blast_contam $wdir/" . $jobname .  "_Intermediate/" . $jobname . "_kmer_contam_contigs";
#	exit;
#  }
  if($counts[0]==0){
	$cmd="rm " . $blast_clean;
        system($cmd);
  }
  if($counts[0]==0 or $known_target=~/^Bacteria;$/ or $known_target=~/^Archaea;$/ ){
        print LOG "prodege_classify.pl: Clean bin is empty.  Using 9-mer with standard cutoff.\n";
	$cmd="perl $bin/prodege_compute_kmer_counts.pl $wdir 9 $jobname; $RCmd CMD BATCH -" . $lib . " -" . $wdir . " -" . 9 . " -" . $jobname .  " -" . $kcutoff . " --no-save " . $bin . "/prodege_classify_noclean.R " . $wdir . "/" . $jobname . "_Intermediate/" . $jobname . "_prodege_classify.out";
  }
  elsif($counts[2]==0){
	#print LOG "scd_classify.pl: Blast contam bin is empty, cannot precalibrate. Using 5-mer with standard cutoff.\n";
        #$cmd="cp " . $blast_clean . " " . $kmer_clean;
        print LOG "prodege_classify.pl: Blast contam bin is empty, cannot precalibrate.  Using 5-mer with standard cutoff.\n";
        $cmd="perl $bin/prodege_compute_kmer_counts.pl $wdir 5 $jobname; $RCmd CMD BATCH -" . $lib . " -" . $wdir . " -" . 5 . " -" . $jobname . " -" . $kcutoff . " --no-save " . $bin . "/prodege_classify_nocontam.R " . $wdir . "/" . $jobname . "_Intermediate/" . $jobname . "_prodege_classify.out";
  }
  else{
        print LOG "prodege_classify.pl: Using 5-mer with refined calibration.\n";
        $cmd="perl $bin/prodege_compute_kmer_counts.pl $wdir 5 $jobname; $RCmd CMD BATCH -" . $lib . " -" . $wdir . " -" . 5 . " -" . $jobname . " -" . $kcutoff . " --no-save " . $bin . "/prodege_classify_cleanandcontam.R " . $wdir . "/" . $jobname . "_Intermediate/" . $jobname . "_prodege_classify.out";
  }
  system($cmd);

  my %cleanc;
  open(IN,$kmer_clean);
  open(OUT,">>$kmer_contam");
  while(my $line=<IN>){
	chomp($line);
	if(exists($checkclean{$line})){
		$cleanc{$line}=1;
	}
	elsif(exists($cl{$line})){
		if($cl{$line}=~$known_target or $known_target=~/$cl{$line}/){
			$cleanc{$line}=1;
		}
		else{
			#print "$line $cl{$line} $known_target\n";
			print OUT $line . "\n";	
		}
	}
	else{
		$cleanc{$line}=1;
	}
  }
  close(IN);
  close(OUT);

  open(OUT,">$kmer_clean");
  for my $key (keys %cleanc){
	print OUT $key . "\n";
  }
  close(OUT);
}
else{
  print LOG "prodege_classify.pl: No binning target.  Using 9-mer with standard cutoff.\n";
  #my $cmd="$RCmd CMD BATCH -" . $lib . " -" . $wdir . " -" . 9 . " -" . $jobname . " --no-save " . $bin . "/scd_classify_nobintarget.R " . $wdir . "/" . $jobname . "_Intermediate/" . $jobname . "_scd_classify.out";
  my $cmd="perl $bin/prodege_compute_kmer_counts.pl $wdir 9 $jobname; $RCmd CMD BATCH -" . $lib . " -" . $wdir . " -" . 9 . " -" . $jobname . " -" . $kcutoff . " --no-save " . $bin . "/prodege_classify_nobintarget.R " . $wdir . "/" . $jobname . "_Intermediate/" . $jobname . "_prodege_classify.out";
  system($cmd);
}

close(LOG);
1;
