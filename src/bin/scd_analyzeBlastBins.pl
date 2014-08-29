#!/usr/bin/env perl

use strict;

my $usage="$0 <Blast outfile> <Bins: with contigs> <Contigs: with bins>\n";

@ARGV==3
  or die "$0: $usage";
my ($blout,$binf,$contigbinf)=@ARGV;

my $species={};
my $contigbins={};
my $genebins={};

open (PBF,$blout) or die "Couldn't open $blout to read\n";
while (<PBF>) {
  chomp($_); my $l=$_; my @a=split(/\t/,$l);
  
  # Get gene and contig information
  my @b=split(/\t/,$a[0]); my $cg=$b[0];
  $cg=~/(.+)_(\d+_\d+)$/; my ($contig,$g)=($1,$2);

  #Begin add Issue #9: >70perid over >70% of gene requirement for hits 
  if($b[2]<70){
	next;
  }
  if($b[3]/$b[4]<.70){
	next;
  }
  #End add Issue #9

  $contigbins->{$contig}={} unless exists $contigbins->{$contig};

  # Extract NR subject species
  my @stitle=split(/ /,pop(@a));
  my $sp;
  ##Issue#1 begin add
  if($stitle[0]=~/\|/){  
	if($stitle[1]=~/Candidatus/ || $stitle[1]=~/candidate division/i){
       	 	$sp=$stitle[1] . " " . $stitle[2]  . " " . $stitle[3];
  	}
  	else{
        	$sp=$stitle[1] . " " . $stitle[2];
  	}
  } 
  else{
  ##Issue#1 end add
  	if($stitle[0]=~/Candidatus/ || $stitle[0]=~/candidate division/i){
  		$sp=$stitle[0] . " " . $stitle[1]  . " " . $stitle[2];
  	}
  	else{
		$sp=$stitle[0] . " " . $stitle[1];
  	}
  ##Issue#1 begin add
  }
  ##Issue#1 end add

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
