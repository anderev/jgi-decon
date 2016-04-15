#!/usr/bin/env perl
#ProDeGe Copyright (c) 2014, The Regents of the University of California,
#through Lawrence Berkeley National Laboratory (subject to receipt of any
#required approvals from the U.S. Dept. of Energy).  All rights reserved.

use strict;
use warnings;
use Bio::SeqIO;
use Bio::Perl;

#Begin Issue #37_c1 binning only if >50% genes have hits
sub getContigName{
  my ($gene)=@_;
  my @b=split(/ # /,$gene);
  my $id=reverse($b[0]);
  my @a=split(/_/,$id);
  shift @a;
  shift @a;
  $id=join("_",@a);
  $id=reverse($id);
  return($id);
} 
#End Issue #73_c1

my $usage="$0 <Blast outfile> <Bins: with contigs> <Contigs: with bins>\n";

unless(@ARGV==3 or @ARGV==4){
	die "$0: $usage";
}
my ($blout,$binf,$contigbinf,$pout)=@ARGV;

my $species={};
my $contigbins={};
my $genebins={};
my %counts;
my %chits;
my %cnames;

#Begin Issue #37_c2 binning only if >50% genes have hits
if($pout){
  my $in=Bio::SeqIO->new(-file => "$pout" ,  -format => 'Fasta');
  while (my $seqobj=$in->next_seq()) {
    my $gene=$seqobj->display_id();
    my $id=getContigName($gene);
    if(exists($cnames{$id})){
      $cnames{$id}++;
    }
    else{
      $cnames{$id}=1;
    }
  }
}
#End Issue #37_c2

open (PBF,$blout) or die "Couldn't open $blout to read\n";
while (<PBF>) {
  chomp($_); my $l=$_; my @a=split(/\t/,$l);
  
  # Get gene and contig information
  my $cg=$a[0];
  $cg=~/(.+)_(\d+_\d+)$/; my ($contig,$g)=($1,$2);

  #Begin add Issue #9: >30perid over >50% of gene requirement for hits 
  if($a[2]<30){
	next;
  }
  if(abs(($a[9]-$a[8]+1))/$a[4]<.50){
	next;
  }
  if(exists($counts{$cg})){
	$counts{$cg}++;
	if($counts{$cg}>2){
        	next;
  	}
  }
  else{
        $counts{$cg}=1;
        #Begin Issue #37_c4
        if(exists($chits{$contig})){
		$chits{$contig}=$chits{$contig}+1;
	}
	else{
        	$chits{$contig}=1;	
	}
        #End Issue #37_c4
  }
  #End add Issue #9

  $contigbins->{$contig}={} unless exists $contigbins->{$contig};

  # Extract NR subject species
  my $st=pop(@a);
  $st=~s/, complete genome//ig;
  $st=~s/, partial sequence//ig;
  my @stitle=split(/ /,$st);
  my $sp;
  if($a[1]=~/^\d/){
	$sp=$a[1];
  }
  else{
  ##Issue#1 begin add
  #print $stitle[0] . "! !" . $stitle[1] . "! !" . $stitle[2]  . "! !" . $stitle[3] . "\n";;
    if($stitle[0]=~/\|/){
        if(($stitle[1]=~/Candidatus/ || $stitle[1]=~/candidate/i || $stitle[2]=~/sp\.$/i || $stitle[1]=~/uncultured/ || $stitle[1]=~/Uncultured/) and $stitle[3]){
                #if(defined($stitle[4])){
                #       $sp=$stitle[1] . " " . $stitle[2]  . " " . $stitle[3] . " " . $stitle[4];
                #}
                #else{          
                        $sp=$stitle[1] . " " . $stitle[2]  . " " . $stitle[3];
                #}
        }
        else{
                $sp=$stitle[1] . " " . $stitle[2];
        }
        if($sp=~/,/){
                my @sparr=split(/,/,$sp);
                $sp=$sparr[0];
        }
    }
    else{
    ##Issue#1 end add
        if(($stitle[0]=~/Candidatus/ || $stitle[0]=~/candidate/i || $stitle[1]=~/sp\.$/i || $stitle[0]=~/uncultured/ || $stitle[0]=~/Uncultured/) and $stitle[2]){
                if(defined($stitle[3])){
                        $sp=$stitle[0] . " " . $stitle[1]  . " " . $stitle[2] . " " . $stitle[3];
                }
                else{
                        $sp=$stitle[0] . " " . $stitle[1]  . " " . $stitle[2];
                }
        }
        else{
                $sp=$stitle[0] . " " . $stitle[1];
        }
    ##Issue#1 begin add
    }
    ##Issue#1 end add
  }


  #print "$contig XX $g XX $sp XX\n";
  if (exists $contigbins->{$contig}->{$sp}) {
    $contigbins->{$contig}->{$sp}=$contigbins->{$contig}->{$sp}+1;
  } else {
    $contigbins->{$contig}->{$sp}=1;
  }
  $species->{$sp}={} unless exists $species->{$sp};
  if (exists $species->{$sp}->{$contig}) {
    $species->{$sp}->{$contig}=$species->{$sp}->{$contig}+1;
  } else {
    $species->{$sp}->{$contig}=1;
  }
}

open(BF,">$binf");
foreach my $sp (keys %{ $species }) {
  my $binsize=0;
  foreach my $c (keys %{ $species->{$sp} }) {
    $binsize+=$species->{$sp}->{$c};
  }
  print BF $sp,"\t",$binsize,"\t";
  foreach my $c (keys %{ $species->{$sp} }) {
    print BF "$c:$species->{$sp}->{$c},";
  }
  print BF "\n";
  #print BF join(',',keys %{ $species->{$sp} }),"\n";
}
close(BF);

open(CF,">$contigbinf");
foreach my $c(keys %{ $contigbins }) {
  #my $numbins=scalar(keys %{ $contigbins->{$c} });
  my $numbins=0;
  foreach my $sp (keys %{ $contigbins->{$c} }) {
    $numbins+=$contigbins->{$c}->{$sp};
  }
  print CF $c,"\t",$numbins,"\t";
  foreach my $sp (keys %{ $contigbins->{$c} }) {
    for (my $i=0; $i<$contigbins->{$c}->{$sp}; $i++) {
      print CF "$sp,";
    }
  }
  print CF "\n";
  #print CF join(',',keys %{ $contigbins->{$c} }),"\n";
}
close(CF);

#Begin Issue #37_c3
if($pout){
  open(STA,">$blout.stats");
  print STA "contig_name\tnum_genes\tnum_genes_w_hits\tfraction\n";
  foreach my $key (keys %cnames){
    print STA $key . "\t$cnames{$key}\t";
    if(exists($chits{$key})){
      print STA $chits{$key} . "\t" . sprintf("%.3f",$chits{$key}/$cnames{$key}) . "\n";
    }
    else{
      print STA "0\t0\n";
    }
  }
  close(STA);
}
#End Issue #37_c3
