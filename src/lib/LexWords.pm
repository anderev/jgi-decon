#!/usr/bin/perl -w

# Module LexWords.pm
######################################
#ProDeGe Copyright (c) 2014, The Regents of the University of California, through Lawrence Berkeley National Laboratory (subject to receipt of any required approvals from the U.S. Dept. of Energy).  All rights reserved.
 
#If you have questions about your rights to use or distribute this software, please contact Berkeley Lab's Innovation & Partnerships Office at  IPO@lbl.gov referring to " ProDeGe (LBNL Ref 2015-021)."
 
#NOTICE.  This software was developed under funding from the U.S. Department of Energy.  As such, the U.S. Government has been granted for itself and others acting on its behalf a paid-up, nonexclusive, irrevocable, worldwide license in the Software to reproduce, prepare derivative works, and perform publicly and display publicly.  Beginning five (5) years after the date permission to assert copyright is obtained from the U.S. Department of Energy, and subject to any subsequent five (5) year renewals, the U.S. Government is granted for itself and others acting on its behalf a paid-up, nonexclusive, irrevocable, worldwide license in the Software to reproduce, prepare derivative works, distribute copies to the public, perform publicly and display publicly, and to permit others to do so.
######################################

package LexWords;
require Exporter;

use strict;
#use Statistics::Distributions;
#use RandSeqGen;

sub Enumerate($);
sub FindDepth($);
sub NextChar($);

my @alph = ("A","C","G","T");
#my @alph = ("0","1");

# Enumerate the next string in the lexicographic order
sub Enumerate($) {
  my $depth = FindDepth($_[0]);
  #print "Depth=$depth\n";
  my $len = length($_[0]);
  my @schars = split(//, $_[0]);
  
  if ($depth == ($len-1)) { #Last string in lexicographic order
    #print "Last string in Lexicographic Order\n";
    #print "No further enumeration done!!\nReturning to main program...\n";
    return($_[0]);
  } elsif ($depth == -1) { #first character to be incremented
    $schars[$len-1-($depth+1)] = NextChar($schars[$len-1-($depth+1)]);
    my $news = join("", @schars);
    return($news);
  } else { #Actual enumeration process activated
    
    for (my $k = ($len-1); $k >= ($len-1-$depth); $k--) {
      $schars[$k] = $alph[0];
    }
    $schars[$len-1-$depth-1] = NextChar($schars[$len-1-$depth-1]);
    my $news = join("", @schars);
    return($news);
  }
}

# Find the greatest index of the input string until 
# which characters are the last character in the 
# lexicographic order
sub FindDepth($) {
  my @sarr = split(//, $_[0]);
  my $depth = -1;
  
  for (my $k = (@sarr-1); $k >= 0; $k--) {
    if ($sarr[$k] eq $alph[@alph-1]) {
      $depth++;
    } else {
      last;
    }
  }

  return($depth);

}

# Find the next character in the given lexicographic order
sub NextChar($) {
  my $nextchar;
  for (my $k = 0; $k < (@alph-1); $k++) {
    if ($_[0] eq $alph[$k]) {
      $nextchar = $alph[$k+1];
      last;
    }
  }
  return($nextchar);
}

# Find the individual nleotide frquencies
# ARG1 String
# Returns Reference to array containing the frequencies
sub getNFreq ($) {
  my $freqarr = ();
  my @nlist = split(//,$_[0]);
  my $sum = 0;
  for (my $i=0; $i<@alph; $i++) {
    $freqarr->[$i] = grep /$alph[$i]/, @nlist;
    $sum = $sum+$freqarr->[$i];
  }
  for (my $i=0; $i<@alph; $i++) {
    my $freq = $freqarr->[$i]/$sum;
    print "$freqarr->[$i]\\ ($freq)\n";
  }
  return($freqarr);
}

# Find the individual nleotide counts
# ARG1 String
# Returns Reference to array containing the counts
sub getNCounts ($) {
  my $freqarr = ();
  my @nlist = split(//,$_[0]);
  my $sum = 0;
  for (my $i=0; $i<@alph; $i++) {
    $freqarr->[$i] = grep /$alph[$i]/, @nlist;
    $sum = $sum+$freqarr->[$i];
  }
  return($freqarr);
}

# get_alph_index: Get index of character in alphabet
# ARG0: Alphabet array ref
# ARG1: character
sub get_alph_index ($$)
{
  my $alph = $_[0];
  for (my $i=0; $i<@$alph; $i++) {
    if($alph->[$i] eq $_[1]) {
      return($i);
    }
  }
}


# Read in sequence froma file
sub readSeq ($) {
  open (INFILE, $_[0]) or die "readSeq: Couldn't open file $_[0] to read\n";
  my $seq = ""; my $readflag=0;
  while (<INFILE>) {
    my $line=$_;
    if ($line=~/^>/) {
      if ($line=~/plasmid/i) {
        print "Plasmid Sequence=$line\nIgnoring ...\n"; $readflag=0;
      } else {
        print "Sequence=$line"; $readflag=1;
      }
    } else {
      chomp($line); $seq = $seq.(uc($line)) if ($readflag);
    }
  }
  close(INFILE);
  return($seq);
}

# Read in sequence froma file
sub readSeq2 ($$) {
  open (INFILE, $_[0]) or die "readSeq: Couldn't open file $_[0] to read\n";
  my $seq = $_[1]; my $readflag=0;
  while (<INFILE>) {
    my $line=$_;
    if ($line=~/$seq/) {
      if ($line=~/plasmid/i) {
        print "Plasmid Sequence=$line\nIgnoring ...\n"; $readflag=0;
      } else {
        print "Sequence=$line"; $readflag=1;
      }
    } else {
      chomp($line); $seq = $seq.(uc($line)) if ($readflag);
    }
  }
  close(INFILE);
  return($seq);
}

# Get sequence name froma file
sub getSeqName ($) {
  my @arr = split(/\//,$_[0]);
  my $filename = $arr[@arr-1];
  $filename=~s/\.fa//g;
  return($filename);
}

# Print an array, given the reference
# ARG1 Array reference
# ARG0 Ref to array containing all words in
# lexicographic order
sub printArr ($$$) {
  for (my $i=0; $i < @{ $_[0] }; $i++) {
    print $_[0]->[$i],":",$_[1]->[$i];
    if ($_[2]) {
      print ",",$_[2]->[$i],"\n";
    } else {
      print "\n";
    }
  }
  print "\n";
  return(1);
}

# Print a hash, given the reference
sub printHash ($) {
  while ((my $key, my $value)=each %{ $_[0] }) {
    print "$key\t$value; \n";
  }
  print "\n";
  return(1);
}

# Test Covergence of word count frequency vectors
# Seq1 = ARG1
# Seq2 = Sequence generated by uniform distribution
# of nleotides
# ARG1 = Seq1
# ARG2 Highest word length to be used
sub testConvFreq ($$) {

  my $lenlim = $_[1];
  my $unfseq = RandSeqGen::genSeq(length($_[0]));
  my $freqarr = getNFreq($unfseq);
  
  for (my $len=2; $len<=$lenlim; $len++) {
    my $lexaref = listStrings($len);
    my $cntarr1 = cntHash2cntArr(getWordCounts($len,$_[0],$lexaref),$lexaref); 
    my $cntarr2 = cntHash2cntArr(getWordCounts($len,$unfseq,$lexaref),$lexaref); 
    #printArr($cntarr1,$lexaref); printArr($cntarr2,$lexaref);
    my $distance = kullback_leibler($cntarr1, $cntarr2);
    print "Kullbeck-Leibler Distance = $distance\n";
    $distance = bray_curtis($cntarr1, $cntarr2);
    print "Bray-Curtis Distance = $distance\n";
  }
}

# Convert a hash of counts to an array of counts
# ARG1 reference to hash to be convereted
# ARG2 Reference to array containing all words of
# given length in lexicographic order
# Returns reference to array containing counts
sub cntHash2cntArr ($$) {

  my $newarr = ();
  for (my $i=0; $i<@{ $_[1] }; $i++) {
    $newarr->[$i] = $_[0]->{$_[1]->[$i]};
  }
  return($newarr);
}

# Test Markov Chain Convergence
# by comparing the transition probabilities 
# of the empirical MC and the derived MC
# ARG1 Sequence to be tested
# ARG2 Highest word length to be tested for
sub testConvMC ($$) {
  
  my $lenlim = $_[1];

  my $prevlexaref = listStrings("1");
  my $prevdertranshash = buildTransitionHash(1,$_[0],$prevlexaref,1);
  print "Word Length\tBray-Curtis\tKullback-Leibler\tL1\tL2\tCosine\n";
  #printTransHash($prevdertranshash,$prevlexaref);
  
  for (my $len=2; $len<=$lenlim; $len++) {
    my $lexaref = listStrings($len);
    my $emptranshash = buildTransitionHash($len,$_[0],$lexaref,1);
    my $dertranshash = buildDerTransHash($len,$_[0],$lexaref,$prevdertranshash,$prevlexaref);

    if ($len==12) {
      print "Printing Transition Hash\n";
      print2TransHash($emptranshash, $dertranshash, $lexaref);
      print "\n";
    }

    # Check for similarity
    my $vec1 = transHash2Array($len,$emptranshash,$lexaref);
    my $vec2 = transHash2Array($len,$dertranshash,$lexaref);

    print "$len\t";
    #my $sim = bray_curtis($vec1, $vec2)/@{ $lexaref };
    #print "Bray-Curtis Distance = $sim\t";
    #print "$sim\t";
    #$sim = kullback_leibler($vec1, $vec2);
    #print "Kullbeck-Leibler Distance = $sim\t";
    #print "$sim\t";
    my $sim = L1($vec1, $vec2);
    #print "L1 Distance = $sim\t";
    print "$sim\n";
    #$sim = L2($vec1, $vec2)/@{ $lexaref };
    #print "L2 Distance = $sim\t";
    #print "$sim\t";
    #$sim = cosine_dist($vec1, $vec2);
    #print "Cosine Distance = $sim\n";
    #print "$sim\n";
    
    $prevdertranshash = $emptranshash;
    $prevlexaref = $lexaref;
  }
}

# Test Markov Chain Convergence
# by comparing the transition probabilities 
# of the empirical MC and the derived MC
# Trim infrequent transitions
# ARG1 Sequence to be tested
# ARG2 Highest word length to be tested for
sub testTrimConvMC ($$) {
  
  my $lenlim = $_[1];

  my $prevlexaref = listStrings("2");
  my $prevdertranshash = buildTransitionHash(2,$_[0],$prevlexaref,1);
  
  for (my $len=3; $len<=$lenlim; $len++) {
    print "At level $len\n";
    my $lexaref = listStrings($len);
    my $emptranshash = buildTransitionHash($len,$_[0],$lexaref,1);
    my $dertranshash = buildTrimDerTransHash($len,$_[0],$lexaref,$prevdertranshash,$prevlexaref);
    my $size = keys %$emptranshash;
    print "Emp hash size = $size\n";
    $size = keys %$dertranshash;
    print "Der hash size = $size\n";

    # Trim emptranshash
    for (my $i=0; $i<@{ $lexaref }; $i++) {
      my $word1 = $lexaref->[$i];
      for (my $j=0; $j<@{ $lexaref }; $j++) {
        my $word2 = $lexaref->[$j];
        if (overlap($len,$word1,$word2)) {
          if (exists $dertranshash->{$word1}->{$word2}) {
	  } else {
            delete $emptranshash->{$word1}->{$word2};
	  }
	}
      }
    }

    # Check for similarity
    my $vec1 = transHash2Array($len,$emptranshash,$lexaref);
    my $vec1size = @{ $vec1 };
    my $vec2 = transHash2Array($len,$dertranshash,$lexaref);
    my $vec2size = @{ $vec2 };
    print "Emp Vec size = $vec1size, Der Vec size = $vec2size\n";

    my $sim = bray_curtis($vec1, $vec2);
    print "Bray-Curtis Distance = $sim\n";
    $sim = kullback_leibler($vec1, $vec2);
    print "Kullback-Leibler Distance = $sim\n";
    $sim = L1($vec1, $vec2);
    print "L1 Distance = $sim\n";
    $sim = L2($vec1, $vec2);
    print "L2 Distance = $sim\n";
    $sim = cosine_dist($vec1, $vec2);
    print "Cosine Distance = $sim\n";

    my $meanvar = meanTransHash($emptranshash, $dertranshash, $lexaref);
    my $stdevvar = stdTransHash($emptranshash, $dertranshash, $lexaref, $meanvar);
    print "Mean = $meanvar; Stdev = $stdevvar\n";
    my $cutoff = $meanvar + $stdevvar;
    print "Cutoff = $cutoff\n";
    
    # Trim emptranshash
    my $trimnum = 1;
    for (my $i=0; $i<@{ $lexaref }; $i++) {
      my $word1 = $lexaref->[$i];
      for (my $j=0; $j<@{ $lexaref }; $j++) {
        my $word2 = $lexaref->[$j];
        if (overlap($len,$word1,$word2)) {
          if (exists $emptranshash->{$word1}->{$word2}) {
            if (($emptranshash->{$word1}->{$word2}-$dertranshash->{$word1}->{$word2}) < $cutoff) {
	      #print "Second Trim ...$trimnum \n"; $trimnum++;
              delete $emptranshash->{$word1}->{$word2};
	    }
	  }
	}
      }
      #$size = keys %{ $emptranshash->{$word1} };
      #print "Emp hash size = $size\n";
      
    }
    $prevlexaref = $lexaref;
    $prevdertranshash = $emptranshash;
  }
}

# Test convergence of Marakov Chains
# of the Real Sequence and a random sequence
# generated by uniform distribution
# ARG1 Sequence to be tested
# ARG2 Highest word length to be tested for 
sub testConvRealUnif ($$) {

  my $lenlim = $_[1];
  my $unfseq = RandSeqGen::genSeq(length($_[0]));
  $_[0] = RandSeqGen::genSeq(length($unfseq));
  for (my $len=2; $len<=$lenlim; $len++) {
    my $lexaref = listStrings($len);
    my $emptranshash = buildTransitionHash($len,$_[0],$lexaref,1);
    my $unftranshash = buildTransitionHash($len,$unfseq,$lexaref,1);
    my $vec1 = transHash2Array($len,$emptranshash,$lexaref);
    my $vec2 = transHash2Array($len,$unftranshash,$lexaref);
    my $sim = bray_curtis($vec1, $vec2);
    print "Bray-Curtis Distance = $sim\n";
    $sim = kullback_leibler($vec1, $vec2);
    print "Kullbeck-Leibler Distance = $sim\n";
  }

}

# Create Array from hash
# ARG1 Hash
# ARG2 Refereence to array with words in lex order 
# Returns Array
sub hash2Array ($$) {
  my $hash = $_[0];
  my $lexaref = $_[1];
  my $array = ();
  for (my $i=0; $i<@$lexaref; $i++) {
    $array->[$i] = $hash->{$lexaref->[$i]};
  }
  return $array;
}

# Create Array from transition hash
# ARG1 Word length
# ARG2 Transition Hash
# ARG3 Refereence to array with words in lex order 
# Returns Array
sub transHash2Array ($$$) {

  my $arref = (); my $idx = 0;
  for (my $i=0; $i<@{ $_[2] }; $i++) {
    my $word1 = $_[2]->[$i];
    for (my $j=0; $j<@{ $_[2] }; $j++) {
      my $word2 = $_[2]->[$j];
      if (overlap($_[0],$word1,$word2)) {
        $arref->[$idx] = $_[1]->{$word1}->{$word2};
	$idx++;
      }
    }
  }
  return($arref);
}

# Create Array from stationary hash
# ARG1 Word length
# ARG2 Transition Hash
# ARG3 Refereence to array with words in lex order 
# Returns Array
sub statHash2Array ($$$) {

  my $arref = (); my $idx = 0;
  for (my $i=0; $i<@{ $_[2] }; $i++) {
    my $word1 = $_[2]->[$i];
    for (my $j=0; $j<@{ $_[2] }; $j++) {
      my $word2 = $_[2]->[$j];
      $arref->[$idx] = $_[1]->{$word1}->{$word2};
      $idx++;
    }
  }
  return($arref);
}


# Build transition hash from previous level transition hash
# ARG1 Word Length
# ARG2 Sequence
# ARG3 Reference to hash containing all ARG1-long words in lex order
# ARG4 Reference to hash containing transition probabilties for words 
# of length ARG1-1
# Returns Reference to transition hash for ARG1 long words
sub buildDerTransHash ($$$$) {

  my $oldtranshash = $_[3];
  my $newtranshash = {};
  my $sumhash = {};

  # Initialize transhash
  for (my $i=0; $i<@{ $_[2] }; $i++) {
    my $word1 = $_[2]->[$i];
    $sumhash->{$word1} = 0;
    $newtranshash->{$word1} = {};
    for (my $j=0; $j<@{ $_[2] }; $j++) {
      my $word2 = $_[2]->[$j];
      
      if (overlap($_[0],$word1,$word2)) {
        $newtranshash->{$word1}->{$word2} = 0;
      }
    }
  }

  # Get transition probabilities
  for (my $i=0; $i<(length($_[1])-$_[0]); $i++) {
    my $word1 = (substr($_[1], $i, $_[0]));
    my $word2 = (substr($_[1], $i+1, $_[0]));
    my $subw2 = (substr($word2, 0, $_[0]-1));
    my $subw3 = (substr($word2, 1, $_[0]-1));
    
    if (overlap($_[0],$word1,$word2)) {
      $newtranshash->{$word1}->{$word2} = $oldtranshash->{$subw2}->{$subw3};
    }
  }
=pod
  # Print Transhash
  for (my $i=0; $i<@{ $_[2] }; $i++) {
    my $word1 = $_[2]->[$i];
    for (my $j=0; $j<@{ $_[2] }; $j++) {
      my $word2 = $_[2]->[$j];
      
      if (overlap($_[0],$word1,$word2)) {
        print "$word1 -> $word2: $newtranshash->{$word1}->{$word2}; ";
      }
    }
  }
  print "\n";
=cut
  return($newtranshash);
}

# Print entries of two transition hashes
# ARG1 Reference to first transition hash
# ARG2 Reference to second transition hash
# ARG3 Reference to array with all words
sub print2TransHash ($$$) {

  print "Transition\tEmpirical probability\tDerived probability\n";
  for (my $i=0; $i<@{ $_[2] }; $i++) {
    my $word1 = $_[2]->[$i];
    for (my $j=0; $j<@{ $_[2] }; $j++) {
      my $word2 = $_[2]->[$j];
      if (overlap(length($word1),$word1,$word2)) {
        my $emptrans = sprintf("%1.3f",$_[0]->{$word1}->{$word2});
        my $dertrans = sprintf("%1.3f",$_[1]->{$word1}->{$word2});
	print "$word1 -> $word2: $_[0]->{$word1}->{$word2} $_[1]->{$word1}->{$word2}\n";
        #print "$word1 -> $word2:\t$emptrans\t$dertrans\n";
      }
    }
  }
  print "\n";

}

# Print entries of a transition hash
# ARG1 Reference to transition hash
# ARG3 Reference to array with all words
sub printTransHash ($$) {

  for (my $i=0; $i<@{ $_[1] }; $i++) {
    my $word1 = $_[1]->[$i];
    for (my $j=0; $j<@{ $_[1] }; $j++) {
      my $word2 = $_[1]->[$j];
      if (overlap(length($word1),$word1,$word2)) {
        print "$word1 -> $word2: $_[0]->{$word1}->{$word2}\n";
      }
    }
  }
  print "\n";

}
# Print entries of a stationary matrix
# ARG1 Reference to stationary dist  hash
# ARG2 Reference to array with all words
# ARG3 log file name
sub printStatMatrix ($$$) {
  
  open (TRANSFILE,">>$_[2]") or die "Couldn't open input file transitionmatrix.txt";
  for (my $i=0; $i<@{ $_[1] }; $i++) {
    my $word1 = $_[1]->[$i];
    for (my $j=0; $j<@{ $_[1] }; $j++) {
      my $word2 = $_[1]->[$j];
        #if ($_[2]==1) {
          print TRANSFILE "$_[0]->{$word1}->{$word2} ";
	#} else {
	  #print "$_[0]->{$word1}->{$word2} ";
	  #print "$word1\t$word2\n" if (!$_[0]->{$word1}->{$word2});
	#}
    }
    #if ($_[2]==1) {
      print TRANSFILE "\n ";
    #} else {
      #print "\n ";
    #}
  }
  close (TRANSFILE);
  return;
}

# Print entries of a transition matrix
# ARG1 Reference to transition hash
# ARG2 Reference to array with all words
# ARG3 1 if printing to file, 0 otherwise
sub printTransMatrix ($$$) {
  
  #print "Print Option=$_[2]\n";
  open (TRANSFILE,">transitionmatrix.txt") or die "Couldn't open input file transitionmatrix.txt";
  for (my $i=0; $i<@{ $_[1] }; $i++) {
    my $word1 = $_[1]->[$i];
    for (my $j=0; $j<@{ $_[1] }; $j++) {
      my $word2 = $_[1]->[$j];
      if (overlap(length($word1),$word1,$word2)) {
        if ($_[2]==1) {
          print TRANSFILE "$_[0]->{$word1}->{$word2} ";
	} else {
          print "$_[0]->{$word1}->{$word2} ";
	}
      } else {
        if ($_[2]==1) {
          print TRANSFILE "0 ";
	} else {
          print "0 ";
	}
      }
    }
    if ($_[2]==1) {
      print TRANSFILE "\n ";
    } else {
      print "\n ";
    }
  }
  close (TRANSFILE);
  return;
}

# Build transition hash from previous level trimmed transition hash
# ARG1 Word Length
# ARG2 Sequence
# ARG3 Reference to hash containing all ARG1-long words in lex order
# ARG4 Reference to hash containing transition probabilties for words 
# of length ARG1-1
# Returns Reference to transition hash for ARG1 long words
sub buildTrimDerTransHash ($$$$) {

  my $oldtranshash = $_[3];
  my $newtranshash = {};
  my $sumhash = {};

  # Initialize transhash
  for (my $i=0; $i<@{ $_[2] }; $i++) {
    my $word1 = $_[2]->[$i];
    $sumhash->{$word1} = 0;
    $newtranshash->{$word1} = {};
    for (my $j=0; $j<@{ $_[2] }; $j++) {
      my $word2 = $_[2]->[$j];
      
      if (overlap($_[0],$word1,$word2)) {
        $newtranshash->{$word1}->{$word2} = 0;
      }
    }
  }

  # Get transition probabilities
  for (my $i=0; $i<(length($_[1])-$_[0]); $i++) {
    my $word1 = (substr($_[1], $i, $_[0]));
    my $word2 = (substr($_[1], $i+1, $_[0]));
    my $subw2 = (substr($word2, 0, $_[0]-1));
    my $subw3 = (substr($word2, 1, $_[0]-1));
    
    if (overlap($_[0],$word1,$word2)) {
      if ($oldtranshash->{$subw2}->{$subw3}) {
        $newtranshash->{$word1}->{$word2} = $oldtranshash->{$subw2}->{$subw3};
      } else {
        delete $newtranshash->{$word1}->{$word2};
      }
    }
  }
=pod 
  # Print Transhash
  for (my $i=0; $i<@{ $_[2] }; $i++) {
    my $word1 = $_[2]->[$i];
    for (my $j=0; $j<@{ $_[2] }; $j++) {
      my $word2 = $_[2]->[$j];
      
      if ($newtranshash->{$word1}->{$word2} && overlap($_[0],$word1,$word2)) {
        print "$word1 -> $word2: $newtranshash->{$word1}->{$word2}; ";
      }
    }
  }
  print "\n";
=cut
  return($newtranshash);
}

# Buiild transition hash from counts
# between lexemes of given length
# ARG0 Word Length
# ARG1 Sequence
# ARG2 Reference to hash containing all words in lex order
# ARG3 If 0, return transition counts. If 1, return probabilities
# Returns the transition hash
sub buildTransitionHash ($$$$) {
  
  my $transhash = {};
  my $sumhash = {};
  #print "Word length = $_[0], Array size",@{ $_[2] },"\n";

  my $word1=''; my $word2='';
  
  # Initialize transhash
  #print "Initializing transition hash ... \n";
  for (my $i=0; $i<@{ $_[2] }; $i++) {
    $word1 = $_[2]->[$i];
    $sumhash->{$word1} = 0;
    $transhash->{$word1} = {};
    for (my $j=0; $j<@{ $_[2] }; $j++) {
      $word2 = $_[2]->[$j];
      if (overlap($_[0],$word1,$word2)) {
        $transhash->{$word1}->{$word2} = 0;
      }
    }
  }

  # Get transition counts
  #print "Getting transition hash counts ... \n";
  for (my $i=0; $i<(length($_[1])-$_[0]); $i++) {
    $word1 = (substr($_[1], $i, $_[0]));
    $word2 = (substr($_[1], $i+1, $_[0]));
    if(exists $transhash->{$word1}->{$word2}) {
    $transhash->{$word1}->{$word2} = $transhash->{$word1}->{$word2}+1;
    $sumhash->{$word1} = $sumhash->{$word1}+1;
    }
  }
  
  if($_[3] == 0) {
    return $transhash;
  } else {
    # Get transition probabilities
    for (my $i=0; $i<@{ $_[2] }; $i++) {
      my $word1 = $_[2]->[$i];
      for (my $j=0; $j<@{ $_[2] }; $j++) {
        my $word2 = $_[2]->[$j];
      
        if (overlap($_[0],$word1,$word2) && ($sumhash->{$word1} != 0)) {
          $transhash->{$word1}->{$word2} = $transhash->{$word1}->{$word2}/$sumhash->{$word1};
        }
      }
    }
    return($transhash);
  }
=pod
  # Print Transhash
  for (my $i=0; $i<@{ $_[2] }; $i++) {
    my $word1 = $_[2]->[$i];
    for (my $j=0; $j<@{ $_[2] }; $j++) {
      my $word2 = $_[2]->[$j];
      
      if (overlap($_[0],$word1,$word2)) {
        print "$word1 -> $word2: $transhash->{$word1}->{$word2}; ";
      }
    }
  }
  print "\n";
=cut
}

# get the mean of all probabilities in the transitionhas
# ARG0 transition hash ref 1
# ARG1 transition hash ref 2
# ARG2 Ref to array of all lexwords
# Returns Mean 
sub meanTransHash ($$$) {
  
  my $mean = 0; my $num = 0;
  for (my $i=0; $i<@{ $_[2] }; $i++) {
    my $word1 = $_[2]->[$i];
    for (my $j=0; $j<@{ $_[2] }; $j++) {
      my $word2 = $_[2]->[$j];
      if (($_[0]->{$word1}->{$word2}) && overlap(length($word1),$word1,$word2)) {
        $mean = $mean + ($_[0]->{$word1}->{$word2}-$_[1]->{$word1}->{$word2});
	#print $_[0]->{$word1}->{$word2}-$_[1]->{$word1}->{$word2},"\n";
	$num++;
      }
    }
  }
  return($mean/$num);
}

# get the mean of all probabilities in the transitionhas
# ARG0 transition hash ref 
# ARG1 Ref to array of all lexwords
# Returns Mean 
sub meanHash ($$) {
  
  my $mean = 0; my $num = 0;
  for (my $i=0; $i<@{ $_[1] }; $i++) {
    my $word1 = $_[1]->[$i];
    for (my $j=0; $j<@{ $_[1] }; $j++) {
      my $word2 = $_[1]->[$j];
      if (($_[0]->{$word1}->{$word2}) && overlap(length($word1),$word1,$word2)) {
        $mean = $mean + ($_[0]->{$word1}->{$word2});
	$num++;
      }
    }
  }
  return($mean/$num);
}

# get the std of all probabilities in the transitionhas
# ARG0 transition hash ref 1
# ARG1 Ref to array of all lexwords
# ARG2 Mean
# Returns Stdev 
sub stdHash ($$$) {

  my $num = 0; my $stdev = 0;
  for (my $i=0; $i<@{ $_[1] }; $i++) {
    my $word1 = $_[1]->[$i];
    for (my $j=0; $j<@{ $_[1] }; $j++) {
      my $word2 = $_[1]->[$j];
      if (($_[0]->{$word1}->{$word2}) && overlap(length($word1),$word1,$word2)) {
        $stdev = $stdev + ((($_[0]->{$word1}->{$word2})-$_[2])*(($_[0]->{$word1}->{$word2})-$_[2]));
	$num++;
      }
    }
  }
  return(sqrt($stdev/$num));
}

# get the std of all probabilities in the transitionhas
# ARG0 transition hash ref 1
# ARG1 transition hash ref 2
# ARG2 Ref to array of all lexwords
# ARG3 Mean
# Returns Stdev 
sub stdTransHash ($$$$) {

  my $num = 0; my $stdev = 0;
  for (my $i=0; $i<@{ $_[2] }; $i++) {
    my $word1 = $_[2]->[$i];
    for (my $j=0; $j<@{ $_[2] }; $j++) {
      my $word2 = $_[2]->[$j];
      if (($_[0]->{$word1}->{$word2}) && overlap(length($word1),$word1,$word2)) {
        $stdev = $stdev + ((($_[0]->{$word1}->{$word2}-$_[1]->{$word1}->{$word2})-$_[3])*(($_[0]->{$word1}->{$word2}-$_[1]->{$word1}->{$word2})-$_[3]));
	$num++;
      }
    }
  }
  return(sqrt($stdev/$num));
}

# Get L1 distance between two vectors
# ARG1 Reference to first vector
# ARG2 Reference to second vector
# Return: L1 distance between the two vectors
sub L1 ($$) {
  
  my $size = @{ $_[0] };
  #print "Size = $size\n";
  my $dist = 0;
  for (my $i=0; $i<@{ $_[0] };$i++) {
    $dist = $dist + abs($_[0]->[$i]-$_[1]->[$i]);
  }
  return($dist);
}

# Get L2 distance between two vectors
# ARG1 Reference to first vector
# ARG2 Reference to second vector
# Return: L2 distance between the two vectors
sub L2 ($$) {
  
  my $dist = 0;
  for (my $i=0; $i<@{ $_[0] };$i++) {
    $dist = $dist + ($_[0]->[$i]-$_[1]->[$i])*($_[0]->[$i]-$_[1]->[$i]);
  }
  return(sqrt($dist));
}

# Get cosine distance between two vectors
# ARG1 Reference to first vector
# ARG2 Reference to second vector
# Return: cosine distance between the two vectors
sub cosine_dist ($$) {
  
  my $dist = 0; my $v1sum = 0; my $v2sum = 0;
  for (my $i=0; $i<@{ $_[0] };$i++) {
    $dist = $dist + ($_[0]->[$i]*$_[1]->[$i]);
    $v1sum = $v1sum + ($_[0]->[$i]*$_[0]->[$i]);
    $v2sum = $v2sum + ($_[1]->[$i]*$_[1]->[$i]);
  }
  return(1-($dist/(sqrt($v1sum)*sqrt($v2sum))));
}

# Check if two words of length l have an overlap of l-1
# ARG1 length
# ARG2 word1
# ARG3 word2
# Returns 1 if they overlap, 0 otherwise
sub overlap ($$$) {
  
  my $word1 = $_[1]; my $word2 = $_[2];
  my $subw1 = (substr($word1, 1, $_[0]-1));
  my $subw2 = (substr($word2, 0, $_[0]-1));
  my $subw3 = (substr($word2, 1, $_[0]-1));

  if ($subw1 eq $subw2) {
    return(1);
  } else {
    return(0);
  }
}

# Get counts of all words of length $_[1]
# in the sequence $_[0]
# ARG1 Word Lenth
# ARG2 SEquence
# ARG3 Reference to array containing all words in lex order
# ARG4 Determines whether to get word counts or word frequencies
# 0 => getCounts, 1 => get Frequencies
# Returns a reference to the hash containing
# counts of all words
sub getWordCounts ($$$$) {
  
  my $cnthash = {};
  my $choice = $_[3];
  # Initialize cnthash
  for (my $i=0; $i<@{ $_[2] }; $i++) {
    $cnthash->{$_[2]->[$i]} = 0;
  }
  
  for (my $i=0; $i<(length($_[1])-$_[0]+1); $i++) {
    my $word = (substr($_[1], $i, $_[0]));
    if(exists $cnthash->{$word}) {
      $cnthash->{$word} = $cnthash->{$word}+1;
    } else {
      $cnthash->{$word} = 1;
    }
  }

  return($cnthash) if ($choice == 0);
  if ($choice == 1) {
    my $occs = length($_[1]) - $_[0] + 1;
    while (my($key,$value) = each %$cnthash) {
      $cnthash->{$key} = $cnthash->{$key}/$occs;
    }
    return($cnthash);
  }
}

# Get counts of all words of length $_[1]
# in the sequence $_[0]
# ARG1 Word Lenth
# ARG2 Sequence
# ARG3 Reference to array containing all words in lex order
# Returns a reference to the hash containing
# counts of all words
# This fm for use with SCD, skip hash2array step
# skip rev comp add to string and bin together rev comp bins
# always return frequences
sub getWordCountsSCD ($$$) {

  my $cnthash = {};
  my $lexaref = $_[2];
  my $choice = $_[3];
  # Initialize cnthash
  for (my $i=0; $i<@{ $_[2] }; $i++) {
    $cnthash->{$_[2]->[$i]} = 0;
  }

  for (my $i=0; $i<(length($_[1])-$_[0]+1); $i++) {
    my $word = (substr($_[1], $i, $_[0]));
    if(exists $cnthash->{$word}) {
      $cnthash->{$word} = $cnthash->{$word}+1;
    } else {
      $cnthash->{$word} = 1;
    }
  }

  my $done = {};
  for (my $i=0; $i<@{ $_[2] }; $i++) {
    $done->{$_[2]->[$i]} = 0;
  }
  while (my($key,$value) = each %$cnthash) {
        if($done->{$key}==0){
                my $revc=revComp($key);
                $done->{$key}=1;
                if($key ne $revc){
                        $done->{$revc}=2;
                        $cnthash->{$key}=$cnthash->{$key}+$cnthash->{$revc};
                        delete $cnthash->{$revc};
                }
		else{
			 $cnthash->{$key}=$cnthash->{$key}*2;
		}
        }
  }

  my $occs = length($_[1]) - $_[0] + 1;
  while (my($key,$value) = each %$cnthash) {
        $cnthash->{$key} = $cnthash->{$key}/$occs;
  }

  my $array = ();
  my $j=0;
  for (my $i=0; $i<@$lexaref; $i++) {
        if($done->{$lexaref->[$i]}==1){
                $array->[$j] = $cnthash->{$lexaref->[$i]};
                $j++;
        }
  }
  return $array;

}

# Get counts of all words of length $_[1]
# in the Double-Stranded sequence $_[0]
# ARG1 Word Lenth
# ARG2 SEquence
# ARG3 Reference to array containing all words in lex order
# ARG4 Determines whether to get word counts or word frequencies
# 0 => getCounts, 1 => get Frequencies
# Returns a reference to the hash containing
# counts of all words
sub getWordCountsDS ($$$$) {
  
  my $cnthash = {};
  my $wlen = $_[0];
  my $seq = $_[1];
  my $lexaref = $_[2];
  my $choice = $_[3];
  my $dscnthash = {};  

  # Initialize cnthash
  for (my $i=0; $i<@{ $lexaref }; $i++) {
    $cnthash->{$lexaref->[$i]} = 0;
  }
  
  for (my $i=0; $i<(length($seq)-$wlen+1); $i++) {
    my $word = (substr($seq, $i, $wlen));
    if(exists $cnthash->{$word}) {
      $cnthash->{$word} = $cnthash->{$word}+1;
    } else {
      $cnthash->{$word} = 1;
    }
  }
  my $occs = (length($seq) - $wlen + 1);
  # Adjust for double stranded DNA
  for (my $i=0; $i<@{ $lexaref }; $i++) {
    $dscnthash->{$lexaref->[$i]} = (($cnthash->{$lexaref->[$i]})/$occs + ($cnthash->{LexWords::revComp($lexaref->[$i])})/$occs)/2 if ($choice==1);
    $dscnthash->{$lexaref->[$i]} = (($cnthash->{$lexaref->[$i]}) + ($cnthash->{LexWords::revComp($lexaref->[$i])}))/2 if ($choice==0);
  }
  return($dscnthash);
}

# revComp: Perl function to get reverse complement
#  	   of a string.
# ARG0:	Input string
# Returns: Reverse complement
sub revComp ($)
{
  my $seq = $_[0];
  my %revhash = (
	A => 'T',
	T => 'A',
	C => 'G',
	G => 'C',
  );
  my $compSeq = '';
  for (my $i=length($seq)-1; $i>=0; $i--) {
    my $char = substr($seq,$i,1);
    next if (!($char=~/A|a|C|c|G|g|T|t/));
    $compSeq = $compSeq.$revhash{$char};
  }
  return($compSeq);
}

# Enumerate strings in lexicographic order
# ARG1 Length of string
# Returns Reference to array containing all strings
# of the given length
sub listStrings ($) {
  
  my $enumarr = (); my $enumcnt = 0;
  #print $_[0];
  # Build base lexeme
  my $baseword = "";
  for (my $k = 0; $k < $_[0]; $k++) {
    if (@alph==4) {
      $baseword = $baseword."A";
    } elsif (@alph==2) {
      $baseword = $baseword."A";
    }
  }
  #print "Baseword=$baseword\n";
  $enumarr->[0] = $baseword;
  #print $enumarr->[0],"\n";
  $enumcnt = 1;
  my $s = $baseword;
  # Enumerate strings in lex order
  while(1) {
    my $nextlex = Enumerate($s);
    if($s eq $nextlex) {
      last;
    } else {
      $enumarr->[$enumcnt] = $nextlex; $enumcnt++;
      #print $nextlex," ";
      $s = $nextlex;
    }
  }
  #printArr($enumarr); 
  #print "Returning from ListStrings\n";
  return($enumarr);

}

sub getReverseLexHash($) {

  my $lexaref = $_[0];
  my $revHash = ();
  for (my $i=0; $i<@{ $lexaref }; $i++) {
    $revHash->{$lexaref->[$i]} = $i;
  }
  return($revHash);
}

# Get the Bray-Curtis/Sorensen correlation between two vectors
# Bray-Curtis or Sorensen similarity measure is defined as
# (sum(|x_i - y_i|))/(sum(x_i + y_i))
# ARG1 Reference to Vector 1
# ARG2 Reference to Vector 2
# Returns: The Bray-Curtis/Sorensen similarity measure
sub bray_curtis ($$) {
  
  my $len1 = @{ $_[0] };
  my $len2 = @{ $_[1] };

  if ($len1 != $len2) {
    print "bray-curtis: Vectors are of unequal length!!\n";
    exit;
  }

  my $num=0; my $den=0;
  for (my $i=0; $i<$len1; $i++) {
    $num = $num + abs($_[0]->[$i] - $_[1]->[$i]);
    $den = $den + $_[0]->[$i] + $_[1]->[$i];
  }
  return($num/$den);
}

# Get the Kullbeck-Leibler correlation between two vectors
# Kulbeck-Leibler similarity measure is defined as
# sum((x_i - y_i)log(x_i/y_i))
# ARG1 Reference to Vector 1
# ARG2 Reference to Vector 2
# Returns: The Kullbeck-Leibler similarity measure
sub kullback_leibler ($$) {
  
  my $len1 = @{ $_[0] };
  my $len2 = @{ $_[1] };

  if ($len1 != $len2) {
    print "kullback_leibler: Vectors are of unequal length!!\n";
    exit;
  }

  my $sum = 0;
  for (my $i=0; $i<$len1; $i++) {
    if ($_[0]->[$i]<0 || $_[1]->[$i]<0) {
      print "Whew!! Probability cannot be negative .. exiting\n";
      exit;
    } elsif ($_[0]->[$i]==0 || $_[1]->[$i]==0) {
      $sum = $sum + 0;
    } else {
      #$sum = $sum + ($_[0]->[$i])*log($_[0]->[$i]/$_[1]->[$i]);
      $sum = $sum + log($_[0]->[$i]/$_[1]->[$i]);
    }
  }
  return($sum);
}

# Get the Chi-Square measure of similarity between two vectors
# Chi-Square similarity measure is defined as
# (f_o - f_e)^2/f_e
# ARG1 Reference to Vector 1
# ARG2 Reference to Vector 2
# Returns: The Chi-Square similarity measure
sub chi_square ($$) {

  my $len1 = @{ $_[0] };
  my $len2 = @{ $_[1] };

  if ($len1 != $len2) {
    print "chi_square: Vectors are of unequal length!!\n";
    exit;
  }
  
  my $rowsums = ();
  my $colsums = ();
  $colsums->[0] = 0; $colsums->[1] = 1;
  for (my $i=0; $i<$len1; $i++) {
    $rowsums->[$i] = $_[0]->[$i] + $_[0]->[$i];
    $colsums->[0] = $colsums->[0] + $_[0]->[$i];
    $colsums->[1] = $colsums->[1] + $_[1]->[$i];
  }
  my $N = $colsums->[1] + $colsums->[0];
  
  my $exp1 = (); my $exp2 = ();
  for (my $i=0; $i<$len1; $i++) {
    $exp1->[$i] = ($rowsums->[$i] * $colsums->[0])/$N;  
    $exp2->[$i] = ($rowsums->[$i] * $colsums->[1])/$N;  
  }

  my $chisq = 0;
  for (my $i=0; $i<$len1; $i++) {
    $chisq = $chisq + ((($_[0]->[$i]-$exp1->[$i])*($_[0]->[$i]-$exp1->[$i]))/$exp1->[$i]) + ((($_[1]->[$i]-$exp2->[$i])*($_[1]->[$i]-$exp2->[$i]))/$exp2->[$i]);
  }
  
  my $chisprob=Statistics::Distributions::chisqrprob($len1-1,$chisq);
  print "Chi Square Probability = $chisprob\n";
  return($chisq);
}

# Subroutine to measure average variation in a genome
# ARG0: Sequence
# ARG1: Order at which to analyze
# ARG2: Lexaref at order
# ARG3: Segment length
# ARG4: Skip length
# Returns: Mean standard deviation of oligonucleotides
sub GenomeVariation ($$$$$) {
  my $seq = $_[0];
  my $w = $_[1];
  my $lexaref = $_[2];
  my $winlen = $_[3];
  my $skiplen = $_[4];

  my $stdhash = {};

  my $globalwordcounts = getWordCounts($w,$seq,$lexaref,1);

  for (my $i=0; $i<@{$lexaref}; $i++) {
    $stdhash->{$lexaref->[$i]} = ();
  }
  # Populate lists with word frequencies
  for (my $i=0; $i<(length($seq)-$winlen+1); $i=$i+$skiplen) {
    my $wordcounts = getWordCounts($w,substr($seq,$i,$winlen),$lexaref,1);
    for (my $j=0; $j<@{$lexaref}; $j++) {
      my $diff = abs($globalwordcounts->{$lexaref->[$j]}-$wordcounts->{$lexaref->[$j]});
      push @{$stdhash->{$lexaref->[$j]}},$diff;
    }
  }
  
  my $meanstdhash = {}; my $totaldev = 0;
  for (my $i=0; $i<@{$lexaref}; $i++) {
    my $stdvec = join(",",@{$stdhash->{$lexaref->[$i]}});
    $meanstdhash->{$lexaref->[$i]} = Vector::VectorMean($stdvec,",");
    my $dev = $meanstdhash->{$lexaref->[$i]};
    $totaldev = $totaldev + $dev;
    print "Word=$lexaref->[$i], Deviation=$dev\n";
  }
  
  print "Total deviation = $totaldev\n";
}

