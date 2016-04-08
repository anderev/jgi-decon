#!/usr/bin/env perl
#ProDeGe Copyright (c) 2014, The Regents of the University of California,
#through Lawrence Berkeley National Laboratory (subject to receipt of any
#required approvals from the U.S. Dept. of Energy).  All rights reserved.

use strict;
use warnings;

sub Checkcomp{
   	my ($bt,$kt)=@_;
   	my @ba=split(/;/,$bt);
   	my @ka=split(/;/,$kt);
   	my $m;
   	if(scalar(@ba)<scalar(@ka)){
		$m=scalar(@ba);
	}
	else{
		$m=scalar(@ka);
	}
	for(my $i=0;$i<$m;$i++){
		if($ba[$i]!~/$ka[$i]/){
			return(0);
		}
	}
   	return(1);
}

my $usage="$0 <directory which contains input fasta file> <jobname>\n";
@ARGV==2 or die $usage;
my $jobname=$ARGV[1];
my $int_dir=$ARGV[0] . "/" . $jobname . "_Intermediate/";
my $contigLCA=$int_dir . $jobname . "_contigs.LCA";
my $outfile=$int_dir . $jobname . "_binning_target";
my $targetfile=$int_dir . $jobname . "_target";
#unless(-e $contigLCA) {die "$contigLCA does not exist.\n";}
#unless(-e $targetfile) {die "$targetfile does not exist.\n";}
unless(-e $contigLCA) {die;}
unless(-e $targetfile) {exit(0);}

open(LOG,">>$ARGV[0]" . "/" . $jobname . "_log");
open(IN,$contigLCA);
my %bh;
my $tlines=0;
while(my $line=<IN>){
	chomp($line);
	$tlines++;
	my @arr=split(/\t/,$line);
	if(defined($arr[1])){
		$arr[1]=~s/^ //g;
		#print $arr[1] . "\n";
		if(exists($bh{$arr[1]})){
			$bh{$arr[1]}=$bh{$arr[1]}+1;
		}else{
			$bh{$arr[1]}=1;
		}
	}	
}
close(IN);

my @sorted_bhkeys=reverse sort{ $bh{$a} <=> $bh{$b} } keys(%bh);
my @sorted_bhvals=@bh{@sorted_bhkeys};
#print scalar(@sorted_bhkeys) . "\n";
#print "$sorted_bhkeys[0]\t$sorted_bhkeys[1]\t$sorted_bhkeys[2]\n";
#print "$sorted_bhvals[0]\t$sorted_bhvals[1]\t$sorted_bhvals[2]\n";

open(IN,$targetfile);
my $known_target=<IN>;
close(IN);
chomp($known_target);
my $full_known_target=$known_target;
my $c=()=$known_target=~/;/g;
if($c<1){
	print LOG "Input taxonomy is not deep enough to use blast binning.\n";
	exit; #not enough to find bin
}
if($c>3){
	my @arr=split(/;/,$known_target);
	while(1){
		pop(@arr);
		my $s=@arr;
		if($s==3){
			last;
		}
	}
	$known_target=join(";",@arr) . ";";
}

my @arr=split(/;/,$known_target);

my $last_key="initialized";
my $bin_target="initialized";
for(my $i=0;$i<scalar(@sorted_bhkeys);$i++){
	my $key=$sorted_bhkeys[$i];
        if($key!~/^Bacteria;$/ and $key!~/^Archaea;$/ and $key!~/^$/ and $key!~/^;$/){		
		#print "#$bh{$key}# \t #$known_target# \t #$key#\n#$full_known_target#\n";
		if($full_known_target=~/$key/ and $bh{$key}>2){
	                $bin_target=$full_known_target;
                        $last_key=$key;
			last;
		}
		if($key=~/$known_target/ and $bh{$key}>2 and &Checkcomp($key,$full_known_target)==1){
			$bin_target=$key;
			last;
		}
	}
}

if(!exists($bh{$bin_target})){
	my $c=()=$last_key=~/;/g;
	if($c>=5){
		$bin_target=$last_key;
	}
}

if(!exists($bh{$bin_target})){
        my @ba=split(/;/,$bin_target); 
	pop(@ba);
	my $nbh=join(";",@ba) . ";";
        my $c=()=$nbh=~/;/g;
	if($c>=5 and exists($bh{$nbh})){
	  if($bh{$nbh}>2){
                $bin_target=$nbh;
	  }
        }
}

if($bin_target!~/initialized/){
  if(exists($bh{$bin_target})){
	#print $bin_target . "\n";
	open(OUT,">$outfile");
	#total number of contigs, number of contigs in this bin, percentage in bin target, bin target
	print OUT $tlines . "\t" ;
	print OUT $bh{$bin_target} . "\t"; 
	print OUT sprintf("%.3f",$bh{$bin_target}/$tlines) . "\t";
	print OUT $bin_target . "\n";
	close(OUT); 
  }
}
print LOG "Binning target is $bin_target.\n";
close(LOG);
