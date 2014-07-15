package BioUtils;

# Author: Amrita Pati, Genome Biology JGI
# Email: apati@lbl.gov
use lib '/house/homedirs/a/apati/GeneQA/Perl';
use lib '/global/homes/a/apati/QA';

use strict;
use GeneticCode;
use Blosum62;
use QAUtils;
use Parser;
use Bio::SeqIO;

# Subroutine to get the length and number of CDSs in each scaffold
# in an annotated genome file
sub getLenNumcds {
  my ($ifile,$ifiletype)=@_;
  my $lens={}; my $numcds={};
  my $in=Bio::SeqIO->new(-file => $ifile, '-format' => $ifiletype);

  while (my $seq = $in->next_seq()) {
    my $seqid=$seq->display_id(); my $cds=0;
    foreach my $feat ($seq->get_SeqFeatures()) {
      my $feattype=$feat->primary_tag;
      $cds++ if ($feattype eq 'CDS');
    }
    $lens->{$seqid}=$seq->length();
    $numcds->{$seqid}=$cds;
  }
  return ($lens,$numcds);
}

# Subroutine to change the name of the query genome
sub modifyGenomeName {
  my $givenselfname=$_[0];
  my $selfname=$givenselfname;
  if ($givenselfname=~/^Escherichia coli/i) { $selfname='Escherichia|Salmonella|Shigella'; }
  if ($givenselfname=~/^lactobacillus/i) { $selfname='Lactobacillus'; }
  if ($givenselfname=~/^Candidatus (\S+) (\S+).*/i) {
    $selfname=$1.' '.$2;
  }
  if ($givenselfname=~/^(\S+) (\S+).*/i) {
    $selfname=$1.' '.$2;
  }
  return ($selfname);
}

# Subroutine to compute the longest common substring between two given strings
# Returns a reference to an array of the longest common substring
sub longestCommonSubString {
  my ($str1, $str2) = @_; 
  my $l_length = 0; # length of longest common substring
  my $len1 = length $str1; 
  my $len2 = length $str2; 
  my @char1 = (undef, split(//, $str1)); # $str1 as array of chars, indexed from 1
  my @char2 = (undef, split(//, $str2)); # $str2 as array of chars, indexed from 1
  my @lc_suffix; # "longest common suffix" table
  my @substrings; # list of common substrings of length $l_length
 
  for my $n1 ( 1 .. $len1 ) { 
    for my $n2 ( 1 .. $len2 ) { 
      if ($char1[$n1] eq $char2[$n2]) {
        # We have found a matching character. Is this the first matching character, or a
        # continuation of previous matching characters? If the former, then the length of
        # the previous matching portion is undefined; set to zero.
        $lc_suffix[$n1-1][$n2-1] ||= 0;
        # In either case, declare the match to be one character longer than the match of
        # characters preceding this character.
        $lc_suffix[$n1][$n2] = $lc_suffix[$n1-1][$n2-1] + 1;
        # If the resulting substring is longer than our previously recorded max length ...
        if ($lc_suffix[$n1][$n2] > $l_length) {
          # ... we record its length as our new max length ...
          $l_length = $lc_suffix[$n1][$n2];
          # ... and clear our result list of shorter substrings.
          @substrings = ();
        }
        # If this substring is equal to our longest ...
        if ($lc_suffix[$n1][$n2] == $l_length) {
          # ... add it to our list of solutions.
          push @substrings, substr($str1, ($n1-$l_length), $l_length);
        }
      }
    }
  }   
 
  #print "STR1=$str1\nSTR2=$str2\nLCS=$substrings[0]\n";
  return \@substrings;
}

# From lengths of query and subject, determine whether a PBR is
# BlastP or BlastX
sub isBlastXorBlastP {
  my $pbr=$_[0]; chomp($pbr);
  my @arr=split(/\n/,$pbr);
  foreach my $line (@arr) {
    next if ($line=~/^Report details/);
    my @larr=split(/\t/,$line);
    my ($qlen,$slen)=($larr[1],$larr[2]);
    if (!$qlen or !$slen) { print "PBR=$pbr**\n,Line=**$line**\n"; }
    if ($qlen>2*$slen) { return('BLASTX'); }
    else { return('BLASTP'); }
  }
}

sub translateDNA2Protein {
    my $dnaseq=$_[0]; my $codonstart=1;
    if (defined $_[1]) { $codonstart=$_[1]; }
    my $protseq='';
    for (my $idx=$codonstart-1; $idx<=length($dnaseq)-3; $idx=$idx+3) {
      $protseq=$protseq.GeneticCode::genCode(uc(substr($dnaseq,$idx,3)));
    }
    return ($protseq);
}

# getOrientation: Subroutine to get the orientation of the alignment
# of an intergenic region
# ARG0: PBR string
# Returns: GENEONRIGHT, GENEONLEFT, or INVERSE
sub getOrientation {
  my $pbr=$_[0]; my @parr=split(/\n/,$pbr); my $orient=''; my $porient='';
  foreach my $hit (@parr) {
    next if ($hit=~/^Report details/);
    my @hitarr=split(/\t/,$hit);
    if ($hitarr[3]<$hitarr[4]) { $orient='GENEONRIGHT'; }
    elsif ($hitarr[4]<$hitarr[3]) { $orient='GENEONLEFT'; }
    if ($porient ne '' && $orient ne $porient) { return('INVERSE'); }
    $porient=$orient;
  }
  return($orient);
}

sub arrAverage ($) {
  my $arr=$_[0]; my $sum=0;
  return ("UNDEF") if (!$arr || @$arr==0);
  for (my $i=0; $i<@$arr; $i++) { $sum+=$arr->[$i]; }
  return($sum/@$arr);
}

sub arrMedian ($) {
  my $arr=$_[0];
  return ("UNDEF") if (!$arr || @$arr==0);
  my $size=@$arr;
  my @sorted=sort {$a <=> $b} @$arr;
  if ($size%2==0) {
    return(($sorted[$size/2-1]+$sorted[$size/2])/2);
  } else {
    return($sorted[$size/2]);
  }
}

# Get average percentage identity values for a parsed blast report
sub getAvgPI {
  my $pbr=$_[0];
  my @parr=split(/\n/,$pbr);
  my $totpi=0; my $numhits=0;
  foreach my $line (@parr) {
    next if ($line=~/^Report details/);
    my @larr=split(/\t/,$line);
    $totpi=$totpi+$larr[8];
    $numhits++;
  }
  $totpi=$totpi/$numhits;
  return($totpi);
}

# Get hash of blast reports for genes constined in genelist
# ARG0: List of genes
# ARG1: File of BRs
# ARG2: Hash to contain BRs
# ARG3: Get all reports if 1
# ARG4: 0, trim aln str, 1 keep aln str
sub getBRs {

  my $genelist=$_[0]; my $brhash=$_[2]; my $alnstr='';
  $alnstr=$_[4] if ($_[4]);
  my $thisid=''; my $line=''; my $thisreport=''; my $geneid=''; my $absent=0; my $arehits=1;
  open (BR,$_[1]) or die "Couldn't open $_[1] to read\n";
  while (<BR>) {
    chomp($_); $line=$_;
    if ($line=~/^BLAST/) {
      $thisreport=~s/&nbsp;&nbsp;<BR>\n/<BR>\n/g;
      $thisreport=~s/<BR>\n<BR>\n<BR>\n/<BR>\n<BR>\n/g;
      if ($_[3]==1) { $brhash->{$geneid}=$thisreport; }
      elsif ($thisreport ne '' && exists $genelist->{$geneid}) { $brhash->{$geneid}=$thisreport; }
      $thisreport=''; $absent=0; $arehits=1; $geneid=''; next; }
    elsif ($absent) { next; }
    elsif ($line=~/Query=\s(.+)$/) { $geneid=$1; $absent=1 if (!exists $genelist->{$geneid}); }
    elsif ($line=~m/No hits found/) { $arehits=0; }
  } continue {
    if (!$absent || $_[3]==1) {
      if (($line=~/^\s*(BLASTP|Reference: Altschul|Jinghui|Database:|"|programs|.+ sequences;\s+.+ total letters|Searching|Subset of the|Posted date:|Number of|Lambda|\d+\.\d+\s+\d+\.\d+\s+\d+\.\d+|Gap|Matrix|Number of|length of|effective|.+bits.+|\c:\s\d+|([\|\\\/]+\s*)+|([A-Z]+\s+)+)/ && !($line=~/Query=/) && !($line=~/^QUERY/) && $alnstr==0) || ($line=~/^\s*(BLASTP|Reference: Altschul|Jinghui|Database:|"|programs|.+ sequences;\s+.+ total letters|Searching|Subset of the|Posted date:|Number of|Lambda|\d+\.\d+\s+\d+\.\d+\s+\d+\.\d+|Gap|Matrix|Number of|length of|effective|.+bits.+|\c:\s\d+|([\|\\\/]+\s*)+)/ && !($line=~/Query=/) && !($line=~/^QUERY/) && $alnstr==1)) { }
      else {
        $line=~s/ /&nbsp;/g;
        $thisreport.=$line."<BR>\n";
      }
    }
  } close(BR);
  if ($thisreport ne '' && (exists $genelist->{$geneid} || $_[3]==1)) { $brhash->{$geneid}=$thisreport; }
}

sub getBRsplain ($$$$) {
  my ($genelist,$brfile,$brhash,$selectall)=@_;
  #print "Keys of genelist=",join(' ',keys %{ $genelist }),"\n";

  my $thisid=''; my $line=''; my $thisreport=''; my $geneid=''; my $absent=0; my $arehits=1;
  my $qon=0; my $qline='';
  open (BR,$brfile) or die "Couldn't open $brhash to read\n";
  while (<BR>) {
    chomp($_); $line=$_;
    if ($qon && $line=~/^\s*$/) {
      next;
    }
    elsif ($qon && $line=~/^Database/) {
      # Parse out query name at this point
      $qline=~s/\n//g;
      #print "Qline=$qline**\n";
      $qline=~/Query=\s(.+)\s+\([0-9,]+ letters\)/;
      $geneid=$1; $geneid=~s/\s+$//g;
      #print "GeneID=$geneid, Genelist->geneid=$genelist->{$geneid}\n";
      $absent=1 if (!exists $genelist->{$geneid});
      $qline=''; $qon=0;
    }
    elsif ($qon) { $qline.=$line; }
    elsif ($line=~/^BLAST/) {
      $thisreport=~s/&nbsp;&nbsp;<BR>\n/<BR>\n/g;
      $thisreport=~s/<BR>\n<BR>\n<BR>\n/<BR>\n<BR>\n/g;
      if ($thisreport ne '' && $selectall==1) { $brhash->{$geneid}=$thisreport; }
      elsif ($thisreport ne '' && exists $genelist->{$geneid}) { $brhash->{$geneid}=$thisreport; }
      $thisreport=''; $absent=0; $arehits=1; $geneid='';
      $qon=0; $qline=''; next;
    }
    elsif ($absent) { next; }
    elsif ($line=~/Query=\s(.+).*$/ && $qon==0) {
      $qon=1;
      $qline.=$line;
    }
    elsif ($line=~m/No hits found/) { $arehits=0; }
  } continue {
    if (!$absent || $selectall==1) {
      $thisreport.=$line."\n";
    }
  } close(BR);
  if ($thisreport ne '' && (exists $genelist->{$geneid} || $selectall==1)) { $brhash->{$geneid}=$thisreport; }
}

# Get hash of parsed blast reports for genes contained in genelist
# ARG0: List of genes
# ARG1: File of PBRs
# ARG2: Hash to contain PBRs
# ARG3: Get all reports if 1
sub getPBRs ($$$$) {

  my $genelist=$_[0]; my $pbrhash=$_[2];

  my $thisid=''; my $line=''; my $thisreport=''; my $geneid=''; my $absent=0;
  open (PBR,$_[1]) or die "Couldn't open $_[1] to read\n";
  while (<PBR>) {
    chomp($_); $line=$_;
    if ($line=~/^Report details: Query=\s?(\S+)\s.+/) { $thisid=$1;
      if ($_[3]==1) { $pbrhash->{$geneid}=$thisreport if ($geneid ne ''); }
      elsif ($thisreport ne '' && exists $genelist->{$geneid}) { $pbrhash->{$geneid}=$thisreport if ($geneid ne ''); }
      $geneid=$thisid; $absent=1 if (!exists $genelist->{$geneid});
      $thisreport=''; $absent=0; next;
    } elsif ($absent) { next; }
  } continue {
    #if (!$absent) { $thisreport.=$line."<BR>\n"; } # Change to this for databases
    if (!$absent || $_[3]==1) {
      $thisreport.=$line."\n";
    }
  }
  close(PBR);
  if ($thisreport ne '' && (exists $genelist->{$geneid} || $_[3]==1)) { $pbrhash->{$geneid}=$thisreport if ($geneid ne ''); }

}

# putIntoHash: Put a certain field of a file into a hash
# ARG0: File
# ARG1: Field that serves as key
# ARG2: Field that serves as value, value should be 1 if this number is 0,
# 	and the entire line if the value is -1
# ARG3: Hash
# ARG4: Delimiter
# ARG5: Overwrite hash value if it already exists? if 1, not if 0
# ARG6: Hash of IDs, only values corresponding to which should be fetched
# ARGs: The remaining arguments are constraints. For example, if we want for the
# 	record being extracted that the 2nd field be "SHORT", then the constraint is
# 	2:SHORT
sub putIntoHash {
  my $keyfield=$_[1]-1; my $valfield=$_[2]-1; my $hash=$_[3];
  my $delim=$_[4]; my $overwrite=$_[5]; my $idHash=$_[6];

  my $constraintidx=(); my $constraints=(); my $i=7; my $cnt=0;
  while ($_[$i]) {
    my @arr=split(':',$_[$i]);
    $constraintidx->[$cnt]=$arr[0]-1; $constraints->[$cnt]=$arr[1];
    $cnt++; $i++;
  }
  open (HF,$_[0]) or die "putIntoHash: Couldn't open $_[0] to read\n";
  my $chosen=0; $chosen=1 if ($idHash);
  while (<HF>) {
    chomp($_); my $line=$_; my @arr=split("$delim",$line); my $flag=1; my $size=@arr;
    next if ($chosen && !(exists $idHash->{$arr[$keyfield]}));
    for (my $i=0; $i<$cnt; $i++) {
      if ($arr[$constraintidx->[$i]]=~/$constraints->[$i]/) { next; }
      else { $flag=0; last; }
    }
    if ($flag) {
      if (exists $hash->{$arr[$keyfield]} && $overwrite) {
        if ($valfield>=0) { $hash->{$arr[$keyfield]}=$arr[$valfield]; }
        elsif ($valfield==-2) { $hash->{$arr[$keyfield]}=$line; }
        elsif ($valfield==-1) { $hash->{$arr[$keyfield]}=1; }
      } else {
        if ($valfield>=0) { $hash->{$arr[$keyfield]}=$arr[$valfield]; }
        elsif ($valfield==-2) { $hash->{$arr[$keyfield]}=$line; }
        elsif ($valfield==-1) { $hash->{$arr[$keyfield]}=1; }
      }
    }
  } close (HF);
}

# getCommonHits: Returns the hash of common hits that two PBRs have
# ARG0: First PBR
# ARG1: Second PBR
# ARG2: Exclude hits in the second file that have frameshits and/or stop codon
# 	in their alignment? Yes if 1, np otherwise
sub getCommonHits ($$$) {
  my $pbr1=$_[0]; my $pbr2=$_[1]; my $filter=$_[2];
  #print "BioUtils::getCommonHits:\nPBR1=$pbr1\nPBR2=$pbr2\n";
  my $commHits={};
  my $hithash={}; my $numCommHits=0;
  my @arr=split(/\n/,$pbr1);
  foreach my $hit (@arr) {
    next if ($hit=~/^Report details/);
    my @larr=split(/\t/,$hit); $hithash->{$larr[0]}=$hit;
  }
  @arr=(); @arr=split(/\n/,$pbr2);
  foreach my $hit (@arr) {
    next if ($hit=~/^Report details/);
    my @larr=split(/\t/,$hit);
    if (exists $hithash->{$larr[0]}) {
      if ($filter) {
        # ** If intergenic blast alignment has no frameshifts or stop codons **
	if ($larr[12] eq 'NONE' && $larr[13] eq 'NONE') {
	  $commHits->{$larr[0]}=$hit.'###'.$hithash->{$larr[0]};
	  $numCommHits++;
	}
      } else {
	$commHits->{$larr[0]}=$hit.'###'.$hithash->{$larr[0]};
	$numCommHits++;
      }
    }
  }
  return($commHits);
}

# getMedianBlastpOffset: Compute the median BlastP offset given a BlastP report
sub getMedianBlastPOffset {
  my $pbr=$_[0]; my @offsetarr;
  my @arr=split(/\n/,$pbr);
  foreach my $hit (@arr) {
    next if ($hit=~/^Report details/);
    my @hitarr=split(/\t/,$hit);
    push @offsetarr, $hitarr[5]-$hitarr[3];
  }
  my @sortedoffsetarr=sort {$a <=> $b} @offsetarr;
  my $arridx=(@sortedoffsetarr%2==0)?(@sortedoffsetarr/2):int(@sortedoffsetarr/2);
  return($sortedoffsetarr[$arridx]);
}

# getMedianSubLen: Get the median subject length for all hits in a Blast report
sub getMedianSubLen {
  my $pbr=$_[0]; my @slens;
  foreach my $hit (split(/\n/,$pbr)) {
    next if ($hit=~/^Report details/);
    my @harr=split(/\t/,$hit);
    push @slens, $harr[2];
  }
  my @sortedslenarr=sort {$a <=> $b} @slens;
  my $arridx=(@sortedslenarr%2==0)?(@sortedslenarr/2):int(@sortedslenarr/2);
  return($sortedslenarr[$arridx]);
}

# findUpsStopCodon: Find stop codon in the upstream region of a gene in the same frame
# 		    as the gene
sub findUpsStopCodon {

  my ($gene,$region,$gstarts,$gends,$seq,$orient,$idprefix)=@_;
  my $regionend=0; my $searchstart=0;
  my @arr=split(',',$region);

  if ($orient eq 'GENEONRIGHT') {
    for (my $idx=0; $idx<@arr; $idx++) {
      if ($arr[$idx]!~/-/ && $arr[$idx]=~/^$idprefix.+/) { # gene
	$searchstart=$gstarts->{$arr[$idx]}-1; last;
      }
    }
    for (my $idx=$searchstart; $idx>0; $idx=$idx-3) {
      my $codon=uc(substr($seq,$idx-3,3));
      if (GeneticCode::genCode($codon) eq '*') {
	$regionend=$idx+1; last;
      }
    }
  } elsif ($orient eq 'GENEONLEFT') {
    for (my $idx=@arr-1; $idx>=0; $idx--) {
      if ($arr[$idx]!~/-/ && $arr[$idx]=~/^$idprefix.+/) { # gene
	$searchstart=$gends->{$arr[$idx]}-1; last;
      }
    }
    for (my $idx=$searchstart; $idx<length($seq)-2; $idx=$idx+3) {
      my $codon=Parser::revComp(uc(substr($seq,$idx+1,3)));
      if (GeneticCode::genCode($codon) eq '*') {
	$regionend=$idx+1; last;
      }
    }
  }
  return($regionend);
}

# findStop:	Find a STOP codon in a given nt sequence
# Returns:	The number and type of stop codon in sequence
sub findStopDetails {
  my $numstops=0; my $stopkind=''; my $subseq='';
  if (scalar(@_)==4) {
    my ($artf,$start,$stop,$orient)=@_;
    my $seq=QAUtils::getARTFSequence($artf);
    if ($orient eq '+') {
      $subseq=uc(substr($seq,$start-1,$stop-$start+1));
    } elsif ($orient eq '-') {
      $subseq=uc(Parser::revComp(substr($seq,$stop-1,$start-$stop+1)));
    }
  } elsif (scalar(@_)==3) {
    my ($artf,$orient,$fscoords)=@_;
    my $seq=QAUtils::getARTFSequence($artf); my $subseq='';
    $fscoords=~s/join|complement|\(|\)//g;
    my @fsarr=split(',',$fscoords);
    foreach my $seg (@fsarr) {
      $seg=~/(\d+)\.\.(\d+)/; my ($start,$stop)=($1,$2);
      if ($orient eq '+') {
	$subseq=$subseq.substr($seq,$start-1,$stop-$start+1);
      } elsif ($orient eq '-') {
	$subseq=Parser::revComp(substr($seq,$start-1,$stop-$start+1)).$subseq;
      }
    }
  }
  for (my $idx=0; $idx<=length($subseq)-6; $idx=$idx+3) {
    if (GeneticCode::genCode(uc(substr($subseq,$idx,3))) eq '*') {
      $numstops++; $stopkind=uc(substr($subseq,$idx,3));
      print "BioUtils::findStopDetails: Found STOP codon\n";
    }
  }
  return($numstops,$stopkind);
}

# getAdjIntergenicIDs: 	Given a gene ID and the strand on which it is located,
# 			compute the ID of the intergenic region located on the
# 			5p end of the gene
# ARG0:			Gene ID
# ARG1:			Strand on which the gene is located
# ARG2:			Uniquei/Dubious genes hash
# ARG3:			Parsed art file
# ARG4:			Intergenic regions file
# ARG5:			Intergenic regions starts
# ARG6:			Intergenic regions ends
# ARG7:			Gene starts
# ARG8:			Gene ends
# Returns:		IDs of the intergenic regions, 5p, then 3p
sub getAdjIntergenicIDs ($$$$$$$$$) {
  my ($geneID,$signs,$udgenes,$partf,$intfile,$intstarts,$intends,$genestarts,$geneends)=@_;
  my $LNbors={}; my $RNbors={}; my $intergenics={}; my $sign='';
  $partf=~/(.+)_(.+)/; my $path=$1; my $idfile=$path."_id.txt";
  my $idprefix=QAUtils::getIDprefix($idfile);

  getNborFeats($partf,$LNbors,$RNbors);
  BioUtils::putIntoHash($intfile,2,0,$intergenics,"\t",1,'');
  my ($n5pgeneID,$n3pgeneID) = ('','');
  my ($ir5p,$ir3p)=('','');

  my ($leftgene,$rightgene)=('','');
  if ($geneID=~/,/) {
    my @arr=split(/,/,$geneID);
    ($leftgene,$rightgene)=($arr[0],$arr[@arr-1]);
  } else {
    ($leftgene,$rightgene)=($geneID,$geneID);
  }
  $sign=$signs->{$leftgene};

  # Do computations assuming +ve sign, while returning, recheck sign
  # and swap if necessary
  $n5pgeneID=$LNbors->{$leftgene}; $n3pgeneID=$RNbors->{$rightgene};
  #print "getAdjIntergenicIDs: n5p=$n5pgeneID, n3p=$n3pgeneID, leftgene=$leftgene, rightgene=$rightgene\n";

  # left intergenic ID
  my $checkedcnt=0;
  while (1) {
    $checkedcnt++;
    if (exists $intergenics->{$n5pgeneID.'-'.$leftgene}) {
      $ir5p=$n5pgeneID.'-'.$leftgene; last;
    } else { 
      if ($checkedcnt==10) { $ir5p=''; last; }
      if (exists $LNbors->{$n5pgeneID}) {
	$n5pgeneID=$LNbors->{$n5pgeneID};
      } else { last; }
    }
  }
  if ($LNbors->{$leftgene} eq $idprefix.'0') { $geneends->{$LNbors->{$leftgene}}=0; }
  if (!(exists $geneends->{$LNbors->{$leftgene}})) {
    print "getAdjIntergenicIDs: Uninitialized gene ends: geneID=$leftgene, LNbor=$LNbors->{$leftgene}\n";
  }
  $intstarts->{$LNbors->{$leftgene}.'-'.$leftgene}=$geneends->{$LNbors->{$leftgene}}+1;
  $intends->{$LNbors->{$leftgene}.'-'.$leftgene}=$genestarts->{$leftgene}-1;
  #print "getAdjIntergenicIDs: Left IR=$ir5p\n";

  # right intergenic ID
  $checkedcnt=0;
  while (1) {
    $checkedcnt++;
    if (exists $intergenics->{$rightgene.'-'.$n3pgeneID}) {
      $ir3p=$rightgene.'-'.$n3pgeneID; last;
    } else {
      if ($checkedcnt==10) { $ir3p=''; last; }
      if (exists $RNbors->{$n3pgeneID}) {
        $n3pgeneID=$RNbors->{$n3pgeneID};
      } else { last; }
    }
  }
  $intstarts->{$rightgene.'-'.$RNbors->{$rightgene}}=$geneends->{$rightgene}+1;
  if (!(exists $genestarts->{$RNbors->{$rightgene}})) {
    print "getAdjIntergenicIDs: Uninitialized gene starts: geneID=$rightgene, RNbor=$RNbors->{$rightgene}\n";
  }
  if ($geneID ne $RNbors->{$rightgene}) {
    $intends->{$rightgene.'-'.$RNbors->{$rightgene}}=$genestarts->{$RNbors->{$rightgene}}-1;
  }
  #print "getAdjIntergenicIDs: Right IR=$ir3p\n";
  
  #print "Sign=$sign\n";
  # return
  if ($sign eq '+') { return($ir5p,$ir3p); }
  elsif ($sign eq '-') { return($ir3p,$ir5p); }
}

# getNborFeats: Capture information about neighboring features in a data structure
# ARG0:	Parsed art file
# ARG1:	Left neighbor hash
# ARG2: Right neighbor hash
sub getNborFeats ($$$) {
  my $parsedArtFile=$_[0]; my $LNbors=$_[1]; my $RNbors=$_[2];
  $parsedArtFile=~/(.+)_(.+)/; my $path=$1; my $idfile=$path."_id.txt";
  my $idprefix=QAUtils::getIDprefix($idfile);
  open(PAF,$parsedArtFile)
    or die "Couldn't open $parsedArtFile to read\n";
  my $pgene='';
  while(<PAF>) {
    chomp($_); my @arr=split(/\t/,$_);
    if ($pgene ne '') {
      $RNbors->{$pgene}=$arr[0]; $LNbors->{$arr[0]}=$pgene;
    } else {
      $LNbors->{$arr[0]}=$idprefix.'0'; $RNbors->{$idprefix.'0'}=$arr[0];
    }
    $pgene=$arr[0];
  }
  $RNbors->{$pgene}=$pgene;
  close(PAF);
  return;
}

# Subroutine to compute the bit score of the blast alignment of a sequence to itself
# ARG0: Protein sequence
# Returns: Self bit score
sub selfBlastPBitScore ($) {
  my $seq=$_[0];
  $seq=~s/\*//g;
  my $s=0; my $K=0.21; my $lambda=0.31455;
  for (my $i=0; $i<length($seq); $i++) {
    $s=$s+Blosum62::blosum62(uc(substr($seq,$i,1)));
  }
  #return($s-log($K*length($seq)*length($seq))/$lambda);
  return($s*$lambda/log(2));
}

# Subroutine to get the subject with the best bit score
sub getSubWithBestBS {
  my $hithash=$_[0]; my $bestsub=''; my $bestbs=0;
  foreach my $sub (keys %{ $hithash }) {
    my @arr=split(/\t/,$hithash->{$sub});
    print "BS=$arr[7], Sub=$arr[0]\n";
    if ($arr[7]>$bestbs) {
      $bestbs=$arr[7]; $bestsub=$arr[0];
    }
  }
  return($bestsub);
}

# Subroutine to blast a sequence to itself using bl2seg
# returns the bit-score of the alignment
# ARG0: Protein sequence
sub bl2seg {
  my $seq=$_[0]; my $pathp='';
  if ($_[1]) { $pathp=$_[1]; }
  $seq=~s/\*//g;
  my $binf=$pathp.time().'_bl2seg.in';
  my $boutf=$pathp.time().'_bl2seg.out';
  open(BI,">$binf") or die "Couldn't open file $binf to write\n";
  print BI ">seq\n$seq\n";
  #print ">seq\n$seq\n";
  close(BI);

  my $blaststr="bl2seq -i $binf -j $binf -p blastp -o $boutf -e 0.00001";
  if (length($seq)<=60) { $blaststr.=" -F F" }
  system($blaststr); my $bitscore=0;
  open(BOF,$boutf) or die "Couldn't open file $boutf\n";
  while (<BOF>) {
    chomp($_); my $line=$_;
    if ($line=~m/Score =\s+(.+) bits/) { $bitscore=$1; last; }
  }
  close(BOF);
  unlink($binf); unlink($boutf);
  return($bitscore);
}

# Check if a given codon is a canonical start codon
sub isCanStartCodon {
  my $codon=$_[0];
  if ($codon eq 'ATG' || $codon eq 'GTG' || $codon eq 'TTG') {
    return(1);
  } else {
    return(0);
  }
}

# Check if a given codon is a non-canonical start codon
sub isNonCanStartCodon {
  my $codon=$_[0];
  if ($codon eq 'ATT' || $codon eq 'ATC' || $codon eq 'CTG') {
    return(1);
  } else {
    return(0);
  }
}

# Check if a given codon is a stop codon
sub isStopCodon {
  my $codon=$_[0];
  if (GeneticCode::genCode(uc($codon)) eq '*') { return(1); }
  else { return(0); }
}

# Convert a PBR to a hash. Return reference to hash
sub pbr2hash {
  my $pbr=$_[0]; my $pbrhash={};
  my @reparr=split(/\n/,$pbr);
  
  foreach my $hit (@reparr) {
    chomp($hit);
    next if ($hit=~/^Report details/);
    my @arr=split(/\t/,$hit);
    $pbrhash->{$arr[0]}=$hit;
  }

  my $hashsize=keys %{ $pbrhash };
  return($pbrhash);
}

# Convert a hash to a PBR. Return PBR
sub hash2pbr {
  my $pbrhash=$_[0]; my $pbr='';
  foreach my $key (keys %{ $pbrhash }) {
    $pbr.="$pbrhash->{$key}\n";
  }
  return($pbr);
}

# Decide if two protein strings match based on their nucleotide strings
# and the presence of Ns in them'
sub proteinsMatch {
  my ($prot1,$prot2)=@_;
  my $mismatches=0;
  
  if (length($prot1)!=length($prot2)) { return(0); }

  my @arr1=split(//,$prot1); my @arr2=split(//,$prot2);
  for (my $i=0; $i<@arr1; $i++) {
    if (($arr1[$i] ne $arr2[$i]) && ($arr1[$i] ne 'X') && ($arr2[$i] ne 'X')) { return(0); }
  }

  return(1);
}

# Given a PBR, find the second shortest and second longest hits
# and the gene length and the e-value of the second shortest hit
sub getSecondShortLongHits {
  my ($pbr,$blasttype)=@_;
  
  if ($pbr eq '') {
    #print "getSecondShortLongHits: Empty PBR!";
    return(1000000000,0,0,100);
  }

  my ($shorthomlen,$secondshorthomlen,$newgenelen,$sev,$ssev,$longhomlen,$secondlonghomlen)=(1000000000,1000000000,0,100,100,0,0);

  my @pbrarr=split(/\n/,$pbr);
  foreach my $line(@pbrarr) {
    next if ($line=~/^Report details/);
    my @linearr=split(/\t/,$line);
    if ($linearr[2]<$secondshorthomlen) {
      if ($linearr[2]==$shorthomlen) {
        next;
      } elsif ($linearr[2]<$shorthomlen) {
	$secondshorthomlen=$shorthomlen; $shorthomlen=$linearr[2];
        $ssev=$sev; $sev=$linearr[11];
      } else {
	$secondshorthomlen=$linearr[2];
	$ssev=$linearr[11];
      }
      if ($blasttype eq 'BLASTP') { $newgenelen=$linearr[1]; }
      elsif ($blasttype eq 'BLASTX') { $newgenelen=$linearr[1]/3; }
    }
    if ($linearr[2]>$secondlonghomlen) {
      if ($linearr[2]==$longhomlen) {
        next;
      } elsif ($linearr[2]>$longhomlen) {
        $secondlonghomlen=$longhomlen; $longhomlen=$linearr[2];
      } else {
	$secondlonghomlen=$linearr[2];
      }
    }
    #print "Shortest=$shorthomlen, Second shortest=$secondshorthomlen, Longest=$longhomlen, Second longest=$secondlonghomlen\n";
  }
  if ($shorthomlen!=1000000000 && $secondshorthomlen==1000000000) { $secondshorthomlen=$shorthomlen; }
  if ($longhomlen!=0 && $secondlonghomlen==0) { $secondlonghomlen=$longhomlen; }
  #print "getSecondShortLongHits: Returning second shortest homolog of length $secondshorthomlen\n"; 

  return($secondshorthomlen,$secondlonghomlen,$newgenelen,$ssev);
}


# areAdjacentXPHits: Determine with rules, if hits of BlastX and hits of BlastP
# 		are adjacent
# The argument side determines whether the IR hits are on the 3p or 5p end of the gene
#
sub areAdjacentXPHits {

  my ($gpbr,$gstart,$gend,$gsign,$ipbr,$istart,$iend,$side,$shortgenes,$gene,$pbr1file)=@_;

  #print "areAdjacentXPhits: Gene=$gene, Side=$side\n";

  if (!($gpbr)) {
    # Check if there was at least one hit in the first Blast run
    my $genelist={}; $genelist->{$gene}=1; my $pbrhash={};
    getPBRs($genelist,$pbr1file,$pbrhash,0);
    if (exists $pbrhash->{$gene} && $pbrhash->{$gene} ne '') { $gpbr=$pbrhash->{$gene}; }
  }

  # If IR is being joined on 5' end of gene and gene is not short, incorrect
  #print "SGHash=$shortgenes->{$gene}\n";
  if ($side eq '5p' && $gpbr && !(exists $shortgenes->{$gene})) { return(0); }

  # If IR is being joined on 3' end of gene, gene should be short on 3' end
  if ($side eq '3p') { }
  
  my $numcommhits=0;
  my $blastXhits=pbr2hash($ipbr);
  #print "IPBR=$ipbr\n\nGPBR=$gpbr\n\n";
  if ($ipbr && $gpbr) {
    my $commhits=getCommonHits($gpbr,$ipbr,0);
    $numcommhits=scalar(keys %{ $commhits });
  }
  
  print "areAdjacentXPHits: Num common hits = $numcommhits\n";
  
  foreach my $key (keys %{ $blastXhits }) {
    my $hit=$blastXhits->{$key}; my @arr=split(/\t/,$hit);
    my $iralnst=$istart+$arr[3]-1; my $iralnend=$istart+$arr[4]-1;
  
    if ($gsign eq '+' && $side eq '5p') {
      if ( ($iralnst<$iralnend) && (($numcommhits>0)||($numcommhits==0 && $gstart-$iralnend<90)) ) {
        return(1);
      }
    } elsif ($gsign eq '+' && $side eq '3p') {
      if ( ($iralnst<$iralnend) && (($numcommhits>0)||($numcommhits==0 && $iralnst-$gend<90)) ) {
        return(1);
      }
    } elsif ($gsign eq '-' && $side eq '5p') {
      if ( ($iralnst>$iralnend) && (($numcommhits>0)||($numcommhits==0 && $iralnend-$gend<90)) ) {
        return(1);
      }
    } elsif ($gsign eq '-' && $side eq '3p') {
      if ( ($iralnst>$iralnend) && (($numcommhits>0)||($numcommhits==0 && $gstart-$iralnst<90)) ) {
        return(1);
      }
    }
  }
  return(0);
}

# get5p3pNeighbors: Return the 5p and 3p neighbors of a feature
#
sub get5p3pNeighbors {
  my ($gene,$gsign,$lnbor,$rnbor)=@_;
  if ($gsign eq '+') { return($lnbor,$rnbor); }
  elsif ($gsign eq '-') { return($rnbor,$lnbor); }
}

# isAdjShortGene: Determine if there is a short (meaning small in length, not short w.r.t. alns)
# 		gene next to this gene
#
sub isAdjShortGene {
  my ($gene,$gsigns,$ngene,$gstarts,$gends,$genepbrs,$side,$shortgenes)=@_;
  #print "isAdjShortGene: Genes *$gene* and *$ngene*, side=$side\n";
  my $gsign=$gsigns->{$gene};
  my $numpbrs=scalar(keys %{ $genepbrs });

  my $shortergene=abs($gends->{$gene}-$gstarts->{$gene})<abs($gends->{$ngene}-$gstarts->{$ngene})?$gene:$ngene;

  if (abs($gends->{$gene}-$gstarts->{$gene})>150 && abs($gends->{$ngene}-$gstarts->{$ngene})>150) {
    return(0);
  }
  #print "isAdjShortGene: At least one gene is longer than 150 bps\n";
  if ($gsign ne $gsigns->{$ngene}) {
    return(0);
  } else {
    my $numcommhits=0;
    if (exists $genepbrs->{$gene} && exists $genepbrs->{$ngene}) {
      my $commhits=getCommonHits($genepbrs->{$gene},$genepbrs->{$ngene},0);
      $numcommhits=scalar(keys %{ $commhits });
    }
    if ($gsign eq '+' && $side eq '5p') {
      if ($shortergene eq $ngene && !(exists $shortgenes->{$gene})) { return(0); }
      if ( $numcommhits>0 || ($numcommhits==0 && $gstarts->{$gene}-$gends->{$ngene}<90) ) {
        return(1);
      }
    } elsif ($gsign eq '+' && $side eq '3p') {
      if ($shortergene eq $gene && !(exists $shortgenes->{$ngene})) { return(0); }
      if ( $numcommhits>0 || ($numcommhits==0 && $gstarts->{$ngene}-$gends->{$gene}<90) ) {
        return(1);
      }
    } elsif ($gsign eq '-' && $side eq '5p') {
      if ($shortergene eq $ngene && !(exists $shortgenes->{$gene})) { return(0); }
      if ( $numcommhits>0 || ($numcommhits==0 && $gstarts->{$ngene}-$gends->{$gene}<90) ) {
        return(1);
      }
    } elsif ($gsign eq '-' && $side eq '3p') {
      if ($shortergene eq $gene && !(exists $shortgenes->{$ngene})) { return(0); }
      if ( $numcommhits>0 || ($numcommhits==0 && $gstarts->{$gene}-$gends->{$ngene}<90) ) {
        #print "isAdjShortGene: Comes till here\n";
        return(1);
      }
    }
  }
  return(0);
}

# getFeatType: Determine the type of the feature as IR/GENE/NR
#
sub getFeatType {
  my ($feat,$idprefix,$allfeats)=@_;
  if ($feat!~/-/) {
    if ($feat=~/^$idprefix.+/) { return('GENE'); }
    else { return('NR'); }
  } else {
    my @arr=split('-',$feat);
    $arr[1]=~s/\(\d+\)//g;
    if ((exists $allfeats->{$arr[0]} || $arr[0] eq $idprefix.'0') && exists $allfeats->{$arr[1]}) {
      return('IR');
    } else { return('NR'); }
  }
}

# get rid of eukaryotic and self-hits from a Blast report
# Get count of hits without frameshifts and stop codons
# Returns:
# PBR w/o euk/self hits
# PBR w/o euk/self/Fs/sc hits
# # good hits w/o fs/sc
sub deleteEukSelfHits {

  my $pbr=$_[0]; my $iseuk=$_[1];
  my $pbrep=''; my $goodpbrep=''; my $numgoodhits=0;
  my @parr=split(/\n/,$pbr);
  foreach my $line (@parr) {
    chomp($line); next if($line=~/^Report details/);
    my @arr=split(/\t/,$line);
    next if (($arr[15]==1 && !($iseuk)) || $arr[16]==1); # Self/euk evaluation
    $pbrep.="$line\n";
    if ($arr[12] eq 'NONE' && $arr[13] eq 'NONE') {
      $numgoodhits++;
      $goodpbrep.=$line;
    }
  }
  return($pbrep,$goodpbrep,$numgoodhits);
}

# get the parsed blast hits of the Blast hit with the best bit score
#
sub getBestBitScoreHit {

  my $hithash=$_[0];
  my $bbs=0; my $bbhit='';

  foreach my $key (keys %{ $hithash }) {
    my @arr=split(/\t/,$hithash->{$key});
    if ($arr[7]>$bbs) { $bbs=$arr[7]; $bbhit=$hithash->{$key}; }
  }
  return($bbhit);
}

# Separate FS SC containing hits ffrom ordinary hits and return the
# separated PBRs and the number of non-FS/SC hits
sub separateFSSChits {
  my $pbr=$_[0];
  my ($fsscpbr,$nonfsscpbr,$numnonfsschits)=('','',0);
  my @arr=split(/\n/,$pbr);
  foreach my $hit (@arr) {
    next if ($hit=~/^Report details/);
    if ($hit=~/FRAMESHIFT|STOPCODON/) {
      $fsscpbr.="$hit\n";
    } else {
      $nonfsscpbr.="$hit\n"; $numnonfsschits++;
    }
  }
  chomp($fsscpbr); chomp($nonfsscpbr);
  return($nonfsscpbr,$fsscpbr,$numnonfsschits);
}

# Analyze the HSPs in a BlastX report.
# Remove hits that have multiple HSPs
# Only keep the hit that has highest overlap with old gene
# Return: newreport w/o hits with multiple HSPs
sub stripHitsWithMultHSPs {
  my ($pbr,$gs,$ge,$rstart,$rend)=@_;
  my @arr=split(/\n/,$pbr);

  my $subjhash={}; my @multhspsubjs; my $newpbr=''; my $ambsubs={};
  my $subhits={};
  if ($rstart>$rend) { my $temp=$rstart; $rstart=$rend; $rend=$temp; }
  
  foreach my $hit (@arr) {
    next if ($hit=~/^Report details/);
    my @darr=split(/\t/,$hit);
    my $hs=$rstart+$darr[3]-1; my $he=$rstart+$darr[4]-1;
    if ($hs>$he) { my $temp=$hs; $hs=$he; $he=$temp; }
    if (!(exists $subhits->{$darr[0]})) {
      $subhits->{$darr[0]}=();
    }
    push @{ $subhits->{$darr[0]} }, $hit;
    #print "stripHitsWithMultHSPs: Hit $hit\n, hs=$hs, he=$he, gs=$gs, ge=$ge\n";
    if (exists $subjhash->{$darr[0]}) {
      $subjhash->{$darr[0]}=$subjhash->{$darr[0]}+1;
    } else {
      $subjhash->{$darr[0]}=1;
    }
  }
  foreach my $hit (@arr) {
    my @darr=split(/\t/,$hit);
    if ($subjhash->{$darr[0]}==1) {
      $newpbr.="$hit\n";
    } elsif ($subjhash->{$darr[0]}>1) {
      my $prefhit=pruneMultHSPhits($subhits->{$darr[0]},$rstart,$gs,$ge);
      if ($prefhit ne '') { $newpbr.="$prefhit\n"; }
    }
  }
  chomp($newpbr);
  return($newpbr);
}

# Decide whether the multiple HSPs need for the hit to be ignored
sub pruneMultHSPhits {
  my ($hits,$rstart,$gs,$ge)=@_; my %deletions;
  for (my $i=0; $i<@{ $hits }; $i++) {
    my @arr1=split(/\t/,$hits->[$i]);
    my ($qs1,$qe1,$ss1,$se1)=($arr1[3],$arr1[4],$arr1[5],$arr1[6]);
    if ($qs1>$qe1) { my $temp=$qs1; $qs1=$qe1; $qe1=$temp; }
    for (my $j=$i+1; $j<@{ $hits }; $j++) {
      my @arr2=split(/\t/,$hits->[$j]);
      my ($qs2,$qe2,$ss2,$se2)=($arr2[3],$arr2[4],$arr2[5],$arr2[6]);
      if ($qs2>$qe2) { my $temp=$qs2; $qs2=$qe2; $qe2=$temp; }
      print "qs1=$qs1, qe1=$qe1, qs2=$qs2, qe2=$qe2\n";
      print "ss1=$ss1, se1=$se1, ss2=$ss2, se2=$se2\n";
      # Means that the two query regions are non-overlapping for the most part
      if (($qs1<$qs2 && abs($qs2-$qe1)<=20)||($qs2<$qs1 && abs($qs1-$qe2)<=20)) {
	# If the two subject regions are non-overlapping for the most part
	if (($ss1<$ss2 && $se1<$ss2)||($ss2<$ss1 && $se2<$ss1)) {
	  # These two hits are to different regions on the subject and should be 
	  # examined manually
	  print "Coming here\n";
	  $deletions{$i}=1; $deletions{$j}=1;
	}
      }
    }
  }
  my @remhits;
  for (my $idx=0; $idx<@{ $hits }; $idx++) {
    if (exists $deletions{$idx}) {
      print "pruneMultHSPhits: Deleting $deletions{$idx}\n";
      delete $hits->[$idx];
    } else {
      push @remhits, $hits->[$idx];
    }
  }
  if (@remhits==0) {
    return('');
  } elsif (@remhits==1) {
    return($remhits[0]);
  } else {
    # If we still have multiple HSPs, choose one
    for (my $i=0; $i<@remhits; $i++) {
      my @rarr=split(/\t/,$remhits[$i]);
      my $hs=$rstart+$rarr[3]-1; my $he=$rstart+$rarr[4]-1;
      if ($hs>$he) { my $temp=$hs; $hs=$he; $he=$temp; }
      # Ensure that hit has overlap with > 50% of the gene
      if (!(($hs<=$gs && $he>=$ge)||($gs<=$hs && $ge>=$he)||($hs<=$gs && $he>=$gs && ($he-$gs)>=0.5*($ge-$gs))||($hs<=$ge && $he>=$ge && ($ge-$hs)>=0.5*($ge-$gs)))) {
        print "pruneMultHSPhits: Ignoring hit $remhits[$i]\n, hs=$hs, he=$he, gs=$gs, ge=$ge\n";
        next;
      } else {
	return($remhits[$i]);
      }
    }
  }
}

# Find what kind of start found
sub getKindOfStart {
  my ($start,$orient,$seq)=@_;
  my $codon=''; my $starttype='UNKNOWN';
  if ($orient eq 'GENEONLEFT') {
    $codon=uc(Parser::revComp(substr($seq,$start-3,3)));
  } elsif ($orient eq 'GENEONRIGHT') {
    $codon=uc(substr($seq,$start-1,3));
  }
  #print "Codon=$codon\n";
  if ($codon eq 'ATG' || $codon eq 'GTG' || $codon eq 'TTG') {
    $starttype='START';
  } elsif ($codon eq 'ATA' || $codon eq 'ATT' || $codon eq 'ATC' || $codon eq 'CTG') {
    $starttype='NONCANSTART';
  }
  return($starttype);
}

# Find the number of self hits in a given hash of Blast hits
sub getNumSelfHits {
  my $hithash=$_[0]; my $numselfhits=0;
  while (my($key,$val)=each %{ $hithash }) {
    my @arr=split(/\t/,$val);
    if ($arr[16]==1) { $numselfhits++; }
  }
  return($numselfhits);
}

# Subroutine to prune draft hits from a report, if there are >=1 hits from complete genomes
sub pruneDraftHits {
  my $pbr=$_[0]; my @arr=split(/\n/,$pbr); my @newarr;
  foreach my $hit (@arr) {
    next if ($hit=~/^Report details/);
    #if ($hit!~/^ZP_/) { push @newarr,$hit; } # Draft genome filter
    if ($hit!~/^[A-Z]D_/) { push @newarr,$hit; } # Draft genome filter
  }
  if (scalar(@newarr)>0) { return (join("\n",@newarr)); }
  else { return($pbr); }
}

# Subroutine to prune hits containing high e-values (>=0.001) from a report
sub pruneHighEVhits {
  my $pbr=$_[0]; my $newpbr='';
  my @arr=split(/\n/,$pbr);
  foreach my $hit (@arr) {
    next if ($hit=~/^Report details/);
    my @harr=split(/\t/,$hit); my $flag=0;
    if ($harr[11]=~/(\d*)e-(\d+)/) {
      my ($c,$e)=($1,$2);
      if (int($e)>=4) { $flag=1; }
      else { $flag=0; }
    } elsif ($harr[11]=~/0\.(\d+)/) {
      if ($harr[11]<0.001) { $flag=1; }
      else { $flag=0; }
    }
    if ($flag) {
      $newpbr.="$hit\n";
    }
  }
  chomp($newpbr);
  return($newpbr);
}

# Subroutine to extract the sequence, given the frameshift coordinates
sub getSeqFromFScoords {
  my ($fscoords,$seq)=@_;
  my $orient=$fscoords=~/complement/?'GENEONLEFT':'GENEONRIGHT';
  $fscoords=~s/join|complement|\(|\)//g;
  my @fsarr=split(',',$fscoords); my $pseq='';
  for (my $i=0; $i<@fsarr; $i++) {
    my $j=@fsarr-1-$i;
    my @arr=split('\.\.',$fsarr[$i]); my @rarr=split('\.\.',$fsarr[$j]);
    if ($orient eq 'GENEONRIGHT') {
      $pseq.=substr($seq,$arr[0]-1,$arr[1]-$arr[0]+1);
    } elsif ($orient eq 'GENEONLEFT') {
      $pseq.=Parser::revComp(uc(substr($seq,$rarr[0]-1,$rarr[1]-$rarr[0]+1)));
    }
  }
  return($pseq);
}

# Subroutine to ascertain whether an Intergenic region contains only semi-unique genes
sub hasSemiUniqGenesOnly {
  my ($ig,$sugenes,$LNbors,$RNbors)=@_;
  my $hassugenesonly=1;
  $ig=~/(.+)-(.+)/; my ($lgene,$rgene)=($1,$2);
  if ($rgene eq $RNbors->{$lgene}) { return(0); }
  else {
    my $nborgene=$RNbors->{$lgene};
    while (1) {
      if ($nborgene eq $rgene) {
	last;
      } else {
	if (!(exists $sugenes->{$nborgene})) {
	  $hassugenesonly=0; last;
	}
	$nborgene=$RNbors->{$nborgene};
      }
    }
  }
  return($hassugenesonly);
}

# Subroutine to determine if a PBR has frameshifts in it
sub hasFrameShifts {
  my $pbr=$_[0];
  my @parr=split(/\n/,$pbr);
  foreach my $hit (@parr) {
    if ($hit=~/FRAMESHIFT/) { return(1); }
  }
  return(0);
}

# Subroutine to get number of hits from PBR
sub getNumHits {
  my $pbr=$_[0]; my $numhits=0;
  my @parr=split(/\n/,$pbr);
  foreach my $hit (@parr) {
    next if ($hit=~/^Report details/);
    $numhits++;
  }
  return ($numhits);
}

# Subroutine to get number of non-eukaryotic and non-self hits hits from PBR
sub getNumNonEukSelfHits {
  my $pbr=$_[0]; my $numhits=0;
  my @parr=split(/\n/,$pbr);
  foreach my $hit (@parr) {
    next if ($hit=~/^Report details/);
    my @harr=split(/\t/,$hit);
    next if ($harr[15]==1 || $harr[16]==1);
    $numhits++;
  }
  return ($numhits);
}

# Sunroutine to remove hits with e-value greater than 0.01
# from PBR
sub removeWeakHits {
  my $pbr=$_[0]; my $newpbr='';
  my @parr=split(/\n/,$pbr);
  foreach my $hit (@parr) {
    next if ($hit=~/^Report details/);
    my @harr=split(/\t/,$hit);
    my $eflag=0; my ($coeff,$exp);
    if ($harr[11]=~/(\d*)e-(\d+)/) {
      ($coeff,$exp)=($1,$2);
      $eflag=1;
    }
    if ((!$eflag && $harr[11]>0.01)||($eflag && $exp<2)) { next; }
    $newpbr=$newpbr."$hit\n";
  }
  chomp($newpbr);
  return($newpbr);
}

# Subroutine to determine file type and number of sequences in a file
sub getFileType {
  
  my $filename=$_[0]; my $format='OTHER'; my $numseqs=0;

  my $grepstr="head -n 1 '$filename' | grep '^>' | wc -l";
  my $retval=`$grepstr`;
  if ($retval==1) {
    $format='fa';
    $grepstr="grep '^>' '$filename' | wc -l";
    $numseqs=`$grepstr`;
  }

  if ($format eq 'OTHER') {
    $grepstr="head -n 1 '$filename' | grep '^ID' | wc -l";
    my $retval=`$grepstr`;
    if ($retval==1) {
      $format='EMBL';
      $grepstr="grep '^ID' '$filename' | wc -l";
      $numseqs=`$grepstr`;
    }
  }

  if ($format eq 'OTHER') {
    $grepstr="head -n 1 '$filename' | grep '^LOCUS' | wc -l";
    my $retval=`$grepstr`;
    if ($retval==1) {
      $format='GB';
      $grepstr="grep '^LOCUS' '$filename' | wc -l";
      $numseqs=`$grepstr`;
    }
  }
  chomp($numseqs);
  return($numseqs,$format);
}

1;
