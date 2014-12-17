#!/usr/bin/env perl
use strict;
use warnings;

#This script creates a file with the complete lineage of every species in the NCBI taxonomy tree
my $usage="$0 <directory which contains nodes.dmp and names.dmp> <file to write to>\n";
@ARGV==2 or die $usage;
my $dir=$ARGV[0];
my $writefile=$ARGV[1];

sub getParentsRecursively {
	my ( $cid, $nodes, $names, $line ) = @_;
	my $pid = ${$nodes}{$cid}{'parent'};
	my $t=${$nodes}{$cid}{'taxc'};
	#if($t=~/^genus$/ or $t=~/^species$/ or $t=~/^family$/ or $t=~/^phylum$/ or $t=~/^class$/ or $t=~/^order$/ or $t=~/^superkingdom$/ or $cid==1 or $cid==131567){
	if($t=~/^genus$/ or $t=~/^species$/ or $t=~/^family$/ or $t=~/^phylum$/ or $t=~/^class$/ or $t=~/^order$/ or $t=~/^superkingdom$/){
		my $cname = ${$names}{$cid};	
		push(@$line,$cname);
	}
	getParentsRecursively ( $pid, $nodes, $names, $line ) if ( $cid != 1 );
}

sub parsetax($) {
	my ($file)=$_[0];
	open my $IN, '<', $file || die "Can't open file '$file': $! ";
	my @lines = <$IN>;
	my %map;
	if ($file=~/names\.dmp/) { # parse names.dmp
		foreach my $line (@lines){
			my @f =split(/\t\|/,$line);
			if ($f[3] eq "\tscientific name") {
				my $id=$f[0];
				my $n=substr($f[1],1);
				$map{$id}=$n;
			}
		}		
	}
	else { # parse nodes.dmp
		foreach my $line (@lines){
			my @f=split(/\t\|/,$line);
			my $cid=$f[0];
			$map{$cid}{'parent'}=substr($f[1],1);
			$f[2]=~s/\s+//g;
			$map{$cid}{'taxc'}=$f[2];
		}
	}
	close($IN);
	return \%map;	
}

my $map_names=parsetax($dir . "/names.dmp");
my $map_nodes=parsetax($dir . "/nodes.dmp");

open(IN,"${dir}/nodes.dmp");
open(OUT,">$writefile");
while(my $line=<IN>){
	if($line=~/\|\tspecies\t\|/){
		my @lineage;
		my @f=split(/\t\|/,$line);
		my $id=$f[0];
		getParentsRecursively($id,$map_nodes,$map_names,\@lineage);
		@lineage=reverse(@lineage);
		print OUT join("\t",@lineage) . "\n";
		#foreach (@lineage){
		#	print OUT $_ . "\t";
		#}
		#print OUT "\n";
	}
}
close IN;
close OUT;
1;

