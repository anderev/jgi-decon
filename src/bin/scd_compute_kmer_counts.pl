#!/usr/bin/env perl

use strict;
use FindBin ();
use lib "$FindBin::Bin";
use lib "$FindBin::Bin/../lib";
use LexWords;
use Bio::SeqIO;
use Bio::Perl;
use List::MoreUtils ':all';


# ARG1 Sequence
# ARG2 Word Length
# ARG3 Reference to array containing all words found in fasta 
# Returns a reference to the hash containing frequency of all words
sub getWordCountsSCD ($$$) {
  my $str=$_[1];
  my $k=$_[0];
  my @lexaref=@{$_[2]};
  my $cnthash = {};
  ## Initialize cnthash
  for (my $i=0; $i<scalar(@lexaref); $i++) {
    $cnthash->{$lexaref[$i]} = 0;
  }
  for (my $i=0; $i<(length($str)-$k+1); $i++) {
    my $word = substr($str,$i,$k);
    my $rcword=LexWords::revComp($word);
    if(exists $cnthash->{$word}) {
      $cnthash->{$word} = $cnthash->{$word}+1;
    } elsif(exists $cnthash->{$rcword}) {
      $cnthash->{$rcword} = $cnthash->{$rcword}+1;
    } else{
      print "Hash initialization incorrect for $word\n";
      exit(1);
    }
  }
#  my $revstr=LexWords::revComp($str);
#  for (my $i=0; $i<(length($str)-$k+1); $i++) {
#    my $word = (substr($revstr, $i, $k));
#    my $rcword=LexWords::revComp($word);
#    if(exists $cnthash->{$word}) {
#      $cnthash->{$word} = $cnthash->{$word}+1;
#    } elsif(exists $cnthash->{$rcword}) {
#      $cnthash->{$rcword} = $cnthash->{$rcword}+1;
#    } else{
#      print "Hash initialization incorrect for $word\n";
#      exit(1);
#    }
#  }

  my $occs =(length($str)-$k+1);
  while (my($key,$value) = each %$cnthash) {
        $cnthash->{$key} = $cnthash->{$key}/$occs;
  }
  my $j=0;
  my $array=();
  for (my $i=0; $i<scalar(@lexaref); $i++) {
        $array->[$j] = $cnthash->{$lexaref[$i]};
        $j++;
  }
  return $array;
}

 
unless(@ARGV==3) {
  print "Usage: $0 <directory of fasta file> <k> <jobname>\n"; exit;
}

my ($wdir,$w,$jobname)=@ARGV;
my $infile=$wdir . "/" . $jobname . "_input.fna";
my $outfile=$wdir . "/" . $jobname . "_Intermediate/" . $jobname . "_contigs_kmervecs_" . $w;

my %exist_words;
my @word_array;
my $in=Bio::SeqIO->new(-file => "$infile" ,  -format => 'Fasta');
while (my $seqobj=$in->next_seq()) {
  my $str=$seqobj->seq();
  my $k=$w;
  for (my $i=0; $i<(length($str)-$k+1); $i++) {
    my $word = (substr($str,$i,$k));
    unless(exists $exist_words{$word}) {
    	my $rcword=LexWords::revComp($word);
        unless(exists $exist_words{$rcword}) {
        	$exist_words{$word} = 1;
	}
    }
  }
  @word_array=keys(%exist_words);
}

open(OUTFILE,">$outfile") or die "$0: Could not open output file $outfile to write\n";
open(OUTN,">" . $outfile . "_names") or die "$0: Couldn't open output file $outfile" . "_names to write\n";
my $in2=Bio::SeqIO->new(-file => "$infile" ,  -format => 'Fasta');
#print OUTFILE join(" ",@word_array) . "\n";
while (my $seqobj=$in2->next_seq()) {
  my $sequence=$seqobj->seq();
  my $kmerarr=getWordCountsSCD($w,$sequence,\@word_array);
  my $dispid=$seqobj->display_id();
  my $kmerstr=join(" ",@$kmerarr);
  print OUTFILE "$kmerstr\n";
  print OUTN "$dispid\n";
}
close (OUTFILE);
close (OUTN);

1;
