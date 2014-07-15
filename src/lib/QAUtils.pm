package QAUtils;

# Author: Amrita Pati, Genome Biology JGI
# Email: apati@lbl.gov

use strict;
use Bio::Perl;
use BioUtils;
use BPlite;
use QAJobs;
use Param;

# prepareBlastInput: Create a fasta file of sequences for blasting
#			from a tab-delimited paf file
sub prepareBlastInput {
  my ($paff,$outf,$idcol,$seqcol)=@_;
  open (PF,$paff)
    or die "Couldn't open $paff to read\n";
  my $out = Bio::SeqIO->new(-file => ">$outf",
                           -format => 'Fasta');
  while (<PF>) {
    chomp($_);
    my @arr=split(/\t/,$_);
    my $thisseq=Bio::Seq->new(	-seq => $arr[$seqcol-1],
				-id => $arr[$idcol-1]
				);
    $out->write_seq($thisseq);
  }
  close (PF);
}

# writeSeqNameToIDfile: Writes the name of the sequence to the ID file
#
sub writeSeqNameToIDfile ($$$) {
  my ($seqfile,$idfile,$seqtype)=@_;
  my $in=Bio::SeqIO->new(-file => $seqfile, '-format' => $seqtype);

  my $seq = $in->next_seq();
  my $seq_disp_id=$seq->id();
  open (IDF,">>$idfile")
    or die "parseGB...:Couldn't open $idfile to write\n";
  print IDF "seqname=$seq_disp_id\n";
  close (IDF);
}

# getSelfTaxOIDstrFromIDF: Retrieves name of the self taxon OID string from id file
#
sub getSelfTaxOIDstrFromIDF ($) {
  my $idfile=$_[0];
  open(IF,$idfile)
    or die "Couldn't open ID file $idfile to read\n";
  my $taxoidstr='';
  while (<IF>) {
    chomp($_); my $line=$_;
    $taxoidstr=$1 if ($line=~/selftaxoids=(.+)/i);
  }
  return($taxoidstr);
}

# getSelfDraft: Retrieves name of the self-draft from id file
#
sub getSelfDraft ($) {
  my $idfile=$_[0];
  open(IF,$idfile)
    or die "Couldn't open ID file $idfile to read\n";
  my $seqname='';
  while (<IF>) {
    chomp($_); my $line=$_;
    $seqname=$1 if ($line=~/selfname=(.+)/i);
  }
  return($seqname);
}

# getSeqName: Retrieves name of sequence from id file
#
sub getSeqName ($) {
  my $idfile=$_[0];
  open(IF,$idfile)
    or die "Couldn't open ID file $idfile to read\n";
  my $seqname='';
  while (<IF>) {
    chomp($_); my $line=$_;
    $seqname=$1 if ($line=~/seqname=(.+)/i);
  }
  return($seqname);
}

# getIDprefix: Retrieve ID prefix for ORFs from id file
#
sub getIDprefix ($) {
  my $idfile=$_[0];
  open(IF,$idfile)
    or die "Couldn't open ID file $idfile to read\n";
  my $idprefix='';
  while (<IF>) {
    chomp($_); my $line=$_;
    $idprefix=$1 if ($line=~/prefix=(.+)/i);
  }
  return($idprefix);
}

# getIsEuk: Retrieve iseuk status from id file
#
sub getIsEuk ($) {
  my $idfile=$_[0];
  open(IF,$idfile)
    or die "Couldn't open ID file $idfile to read\n";
  my $iseuk='';
  while (<IF>) {
    chomp($_); my $line=$_;
    $iseuk=$1 if ($line=~/eukaryote=(.+)/i);
  }
  return(($iseuk eq 'Y')?1:0);
}

# getBlastDB: Get location of Blast database from ID file
sub getBlastDB ($) {
  my $idfile=$_[0];
  open(IF,$idfile)
    or die "Couldn't open ID file $idfile to read\n";
  my $blastdb='';
  while (<IF>) {
    chomp($_); my $line=$_;
    $blastdb=$1 if ($line=~/nr=(.+)/i);
  }
  return($blastdb);
}

# getIsCluster: Retrieve cluster status from ID file
sub getIsCluster ($) {
  my $idfile=$_[0];
  open(IF,$idfile)
    or die "Couldn't open ID file $idfile to read\n";
  my $iscluster='';
  while (<IF>) {
    chomp($_); my $line=$_;
    $iscluster=$1 if ($line=~/cluster=(.+)/i);
  }
  return($iscluster);
}

###############################################################################
# findIntersections: Subroutine to find intersections between
# 		HSPs for any given query and subject.
# Arguments:	ARG1: Hash containing HSP coordinates
# 		ARG2: Number of HSPs
# Returns:	1 if there is an intersection, 0 otherwise
# Author: Amrita Pati, Email: apati@lbl.gov
# Last Updated: 06/13/2008
###############################################################################
sub findIntersections ($$) {
  my $numhsps=$_[1]; my $hsphash=$_[0];
  my ($qb1,$qe1,$qb2,$qe2,$sb1,$se1,$sb2,$se2);
  my $index=-1;

  my $size=keys(%$hsphash);

  # First check for intersections
  for (my $i=1; $i<=$numhsps; $i++) {
    #next if ($hsphash->{$i} eq "DEFUNCT");
    my @arr1=split(/\t/,$hsphash->{$i});
    for (my $j=$i+1; $j<=$numhsps; $j++) {
      #next if ($hsphash->{$j} eq "DEFUNCT");
      my @arr2=split(/\t/,$hsphash->{$j});
      my $lessidx=0;

      # First decide which HSPS query start is smaller
      if ($arr1[3]<$arr2[3]) {
	$qb1=$arr1[3]; $qe1=$arr1[4]; $sb1=$arr1[5]; $se1=$arr1[6];
	$qb2=$arr2[3]; $qe2=$arr2[4]; $sb2=$arr2[5]; $se2=$arr2[6];
	$lessidx=$i;
      } else {
	$qb1=$arr2[3]; $qe1=$arr2[4]; $sb1=$arr2[5]; $se1=$arr2[6];
	$qb2=$arr1[3]; $qe2=$arr1[4]; $sb2=$arr1[5]; $se2=$arr1[6];
	$lessidx=$j;
      }

      # Now check for intersection
      if (($qb2-$qb1>=20 && $qb2<$qe1 && $sb2<$sb1) || $sb1-$sb2>=20) {
        print "QAUtils::findIntersections: Found intersection <$qb1,$qe1,$sb1,$se1> - <$qb2,$qe2,$sb2,$se2>!!\n";
        return(-1);
      }
    }
  }

  # Now check if one alignment region is more or less contained
  # in the other
  for (my $i=1; $i<=$numhsps; $i++) {
    next if ($hsphash->{$i} eq "DEFUNCT");
    my @arr1=split(/\t/,$hsphash->{$i});
    for (my $j=$i+1; $j<=$numhsps; $j++) {
      next if ($hsphash->{$j} eq "DEFUNCT");
      my @arr2=split(/\t/,$hsphash->{$j});
      my $subHSP=isSubHSP($hsphash,$i,$j);
      if ($subHSP==-1) {
	next;
      } elsif ($subHSP==$i) {
	$hsphash->{$i}="DEFUNCT";
      } elsif ($subHSP==$j) {
	$hsphash->{$j}="DEFUNCT";
      }
    }
  }
     
  my $largefrac=0.899;
  # First check if any hit is a large hit
  for (my $i=1; $i<=$size; $i++) {
    next if ($hsphash->{$i} eq "DEFUNCT");
    my @arr=split(/\t/,$hsphash->{$i});
    my $frac=($arr[4]-$arr[3]+1)/$arr[1];
    if ($frac>$largefrac) {
      $largefrac=$frac; $index=$i;
    }
  }
  if ($largefrac>0.9) {
    print "QAUtils::findIntersections: Found large hit among HSPs\n";
    return($index);
  }
      
  $index=selectBestHSP($hsphash);
  return($index);
}

###############################################################################
# selectBestHSP: Subroutine to select the approximate 5' most HSP for
#		 a given Query/Subject pair
# Arguments:	ARG1: Hash containing HSPs
# Returns:	Index of the hash containing the best HSP
# Author: Amrita Pati, Email: apati@lbl.gov
# Last Updated: 06/10/2008
###############################################################################
sub selectBestHSP ($) {

  my $hsphash=$_[0];
  my $size=keys(%$hsphash);

  my $qb=1000000000; my $qe=1000000000; my $sb=1000000000; my $se=1000000000;
  my $index=-1;

  # No hit is large enough
  # Look for N-term-most HSP
  for (my $i=1; $i<=$size; $i++) {
    
    next if ($hsphash->{$i} eq "DEFUNCT");
    my @arr=split(/\t/,$hsphash->{$i});
    my $qbt=$arr[3]; my $sbt=$arr[5];
    if ($qbt>$qb+20) { # Query HSP starts >20 aa 3' of current best HSP
      next;
    } elsif ($qbt<$qb-20) { # Query HSP starts >20 aa 5' of current best HSP
      $qb=$arr[3]; $qe=$arr[4]; $sb=$arr[5]; $se=$arr[6];
      $index=$i;
      next;
    } elsif (($qbt<=$qb && $qbt>=$qb-20)||($qbt>=$qb && $qbt<=$qb+20)) { # Query HSP starts about the same region as current best HSP
      if ($qbt+$sbt<$qb+$sb) { # Sum of Query+Subject starts lesser than current best HSP
        $qb=$arr[3]; $qe=$arr[4]; $sb=$arr[5]; $se=$arr[6];
        $index=$i;
      }
    }
  
  }
  return($index);
}

###############################################################################
# isSubHSP: 	Subroutine to detect if one HSP is approximately contained
#		within another
# Arguments:	ARG1: Hash containing HSPs
# 		ARG2: Index of first HSP
# 		ARG3: Index of second HSP
# Returns:	Index of the hash containing the best HSP
# Author: Amrita Pati, Email: apati@lbl.gov
# Last Updated: 06/10/2008
###############################################################################
sub isSubHSP ($$$) {

  my $index=-1;
  my $hsphash=$_[0];
  my @arr1=split(/\t/,$hsphash->{$_[1]});
  my @arr2=split(/\t/,$hsphash->{$_[2]});
  return($index) if ($hsphash->{$_[1]} eq "DEFUNCT" || $hsphash->{$_[2]} eq "DEFUNCT");

  my $qlen=$arr1[1]; my $qalnlen1=$arr1[4]-$arr1[3];
  my $qalnlen2=$arr2[4]-$arr2[3];
  my $qb1=$arr1[3]; my $qe1=$arr1[4]; my $sb1=$arr1[5]; my $se1=$arr1[6];
  my $qb2=$arr2[3]; my $qe2=$arr2[4]; my $sb2=$arr2[5]; my $se2=$arr2[6];

  if ($qalnlen1>$qalnlen2) {
    if ($qb2>=$qb1 && $qe2<=$qe1 && $sb2>=$sb1 && $se2<=$se1) {
      $index=$_[2]; print "QAUtils::isSubHSP: Found subHSP $arr1[0] of $arr2[0]\n";
    }
  } elsif ($qalnlen2>$qalnlen1) {
    if ($qb2<=$qb1 && $qe2>=$qe1 && $sb2<=$sb1 && $se2>=$se1) {
      $index=$_[1]; print "QAUtils::isSubHSP: Found subHSP $arr2[0] of $arr1[0]\n";
    }
  } elsif ($qalnlen1==$qalnlen2) {
    $index=-1;
  }
  return($index);
}

###############################################################################
# areSameGene: 	Subroutine to determine from blast hits of two predicted genes
# 		if they consititute a single larger gene
# Arguments:	ARG1: ID of gene 1
# 		ARG2: ID of gene 2
# 		ARG3: Blast report of gene 1
# 		ARG4: Blast report of gene 2
#		ARG5: Artemis file sequence
#		ARG6: Broken genes blast reports (unparsed): Output file
# Returns:	parsed blast report, if they are part of the same gene,
# 		0, otherwise.
# Author: Amrita Pati, Email: apati@lbl.gov
# Last Updated: 06/16/2008
###############################################################################
sub areSameGene ($$$$$$$$$$$) {

  my ($id1,$id2,$ppreport,$preport,$sequence,$bgalnfile,$selftaxonOIDstr,$seq1,$seq2,$start1,$start2)=@_;

  if (!($preport) || !($ppreport)) {
    return(0,0,0);
  }
 
  my $idfileprefix=''; my ($fusionflag,$sublendiscflag)=(0,0);
  $idfileprefix=$1 if ($bgalnfile=~/(.+)_brokenGenesAlns.bo/ || $bgalnfile=~/(.+)_brokenAlns.bo/);
  #print "QAUtils::areSameGene: BG aln file=$bgalnfile,\n ID file prefix=$idfileprefix\n";
  my $idfile=$idfileprefix."_id.txt";

  #print "QAUtils::areSameGene: Examining genes $id1 and $id2\n";
  #print "QAUtils::areSameGene: Seq1 len =",length($seq1),"\nSeq2 len=",length($seq2),"\n";

  # First check if they have > 1 common hits
  my $hitshash1={}; my $hitshash2={}; my $commonhits=0;
  my $commonhithash={}; my $hithash1={}; my $hithash2={};
  my $numhits1=0; my $numhits2=0;
  my $slen1=0; my $slen2=0; my $qlen1=0; my $qlen2=0;

  my @arr1=split(/^/,$ppreport); #shift(@arr1);
  my @arr2=split(/^/,$preport); #shift(@arr1);
  #print "ID1=$id1, ID2=$id2\n";

  #print "QAUtils::areSameGene: First hits: \n",join(" ",@arr1),"\nSecond hits: \n",join(" ",@arr2),"\n";

  my $sb1s={}; my $se1s={}; my $sanesubjhits=0; my $fusioncommonhits={}; my (@sublens1,@sublens2);
  my $unknownfusionstatus={};
  
  foreach my $hit (@arr1) {
    next if ($hit eq '' || $hit=~/^Report details/);
    my @hitdata=split(/\t/,$hit);
    $hithash1->{$hitdata[0]}=$hit if (!exists $hithash1->{$hitdata[0]});
    $se1s->{$hitdata[0]}=$hitdata[6]; $sb1s->{$hitdata[0]}=$hitdata[5];
    if ($hitdata[2]>=0.9*length($seq1) && $hitdata[2]<=1.1*length($seq1)) {
      push @sublens1,$hitdata[2];
    }
  }

  foreach my $hit (@arr2) {
    next if ($hit eq '' || $hit=~/^Report details/);
    my @hitdata=split(/\t/,$hit);
    if ($hitdata[2]>=0.9*length($seq2) && $hitdata[2]<=1.1*length($seq2)) {
      push @sublens2,$hitdata[2];
    }
    $hithash2->{$hitdata[0]}=$hit if (!exists $hithash2->{$hitdata[0]});
    if (exists $hithash1->{$hitdata[0]}) {
      # Check here that the common hit does not come from a fusion gene
      my $sub='';
      if ($hitdata[0]=~/(.+)\.(.+)/) { $sub=$1; }
      else { $sub=$hitdata[0]; }
      chomp ($sub);
      next if ($sub eq '' or $sub=~/^\s*$/);
      my $ifg=isFusionGene($sub,3*(length($seq1)+length($seq2)));
      if ($ifg==1) {
	#print "areSameGene: Common hit $hitdata[0] is a fusion gene\n";
	$fusioncommonhits->{$hitdata[0]}=1;
	next;
      } elsif ($ifg==-1) {
	#print "areSameGene: Neglecting $hitdata[0], not in IMG\n";
	$unknownfusionstatus->{$hitdata[0]}=1;
	next;
      }
      $commonhits++; $commonhithash->{$hitdata[0]}=1;
      $slen2=$slen2+$hitdata[2];
      $qlen2=$qlen2+$hitdata[1];
      $numhits2++;
      if (($hitdata[5]>$sb1s->{$hitdata[0]} && $hitdata[5]>$se1s->{$hitdata[0]})||($hitdata[5]<$sb1s->{$hitdata[0]} && $hitdata[6]<$sb1s->{$hitdata[0]})) {
        $sanesubjhits++;
      }
    }
  }

  #foreach my $key (keys %{ $commonhithash }) {
  #  print "Common hit: $key\n";
  #}

  if ($commonhits<2) {
    #print "areSameGene: Less than 2 common hits\n";
    #return(0);
    $fusionflag=1;
  }

  #print "QAUtils::areSameGene: Genes have > 1 common hits\n";

  return(0,$fusionflag,$sublendiscflag) if ($sanesubjhits==0);
  #print "QAUtils::areSameGene: Genes have hits to different regions on the subject\n";

  #print "QAUtils::areSameGene: Sub lens 1 =",join(" ",@sublens1),"\nSub lens 2=",join(" ",@sublens2),"\n";

  # Check that the individual genes are no the same lengths as the subjects they hit
  # If so, the genes may be fused as opposed to being broken
  # Do this only if the two genes are on diff frames
  #if (scalar(@sublens2)>=0.4*scalar(@arr2) && scalar(@sublens1)>=0.4*scalar(@arr1)) {
  if (abs($start1-$start2)%3!=0 && scalar(@sublens2)>=3 && scalar(@sublens1)>=3) {
    #print "QAUtils::areSameGene: Genes are too close in length to their hits, Possible that these are fused genes\n";
    $sublendiscflag=1;
    #return(0);
  }

  # Check if for the common subjects, the average hits lengths are similar for
  # both genes
  # Also check that they hit the subject at segments next to each other
  foreach my $hit (@arr1) {
    my @hitdata=split(/\t/,$hit);
    if (exists $hithash2->{$hitdata[0]} && !(exists $unknownfusionstatus->{$hitdata[0]})) {
      $slen1=$slen1+$hitdata[2];
      $qlen1=$qlen1+$hitdata[1];
      $numhits1++;
    }
  }

  my $bigs=0; my $smalls=0;

  $bigs=($slen1/$numhits1)>($slen2/$numhits2)?($slen1/$numhits1):($slen2/$numhits2);
  $smalls=($slen1/$numhits1)<($slen2/$numhits2)?($slen1/$numhits1):($slen2/$numhits2);

  if ($smalls<0.9*$bigs) {
    #print "QAUtils::areSameGene: Subjects are not of the same length\n";
    return(0,$fusionflag,$sublendiscflag);
  }
  #print "QAUtils::areSameGene: Subjects are approximately of the same length\n";

  # Check if the sum of the query lengths is approximately the subject length
  my $sumq=$qlen1/$numhits1+$qlen2/$numhits2; my $approxs=($slen1/$numhits1 + $slen2/$numhits2)/2;

  $bigs=$sumq>$approxs?$sumq:$approxs;
  $smalls=$sumq<$approxs?$sumq:$approxs;

  # Blast sequence
  #print "QAUtils::areSameGene: Blasting sequence from start of $id1 to end of $id2\n";
  my $tempinfile=$idfileprefix.'_'.time()."in.tmp";
  sleep(1);
  my $tempoutfile=$idfileprefix.'_'.time()."bo.tmp";

  open(TINF,">$tempinfile")
    or die "QAUtils::areSameGene: Couldn't open temporary blast input file $tempinfile to write\n";
  print TINF "$id1.$id2\t$sequence\n";
  close(TINF);
  my $cluster=getIsCluster($idfile);
  my $blaststr="blastall -p blastx -e 0.0001 -b 20 -v 20 -w 15 -a 8";
  if ($cluster eq 'N') { $blaststr.=' -a 8'; }
  my $tempblastfile=$idfileprefix.'_'.time()."bin.tmp";
  QAJobs::runBlast($tempinfile,1,2,$tempblastfile,$tempoutfile,$blaststr);

  #my $selftaxonOIDstr=QAUtils::getSelfTaxOIDstrFromIDF($idfile);
  QAJobs::parseBlastP($tempoutfile,$tempblastfile,"$selftaxonOIDstr");

  unlink($tempinfile);

  # Now check blast hits to see if at least 50% of the common hits are contained
  my $cnt=0; my $report='';
  open(BFILE,$tempblastfile)
    or die "Couldn't open temporary parsed blast output $tempblastfile\n";
  while (<BFILE>) {
    chomp($_); my $line=$_;
    $report=$report.$line."\n";
    next if ($line=~/^Report/);
    my @arr=split(/\t/,$line); chomp($arr[0]);
    $arr[14]=~/(\d+),(\d+)/; my ($numfs,$numsc)=($1,$2);
    if ((exists $commonhithash->{$arr[0]})||(exists $fusioncommonhits->{$arr[0]} && $numfs>=1 && $numfs+$numsc>=2)) {
      $cnt++;
    }
  }
  close(BFILE);
  unlink($tempblastfile);
  
  print "Shared count=$cnt, #Commonhits=$commonhits, Commonhits=",join(" ",keys %{ $commonhithash }),"\n";
  print "Joined report=\n$report\n";
  if ($cnt >= 1) {
    print "QAUtils::areSameGene: Found putative broken gene\n";
    my $cmd="cat $tempoutfile >> $bgalnfile";
    system($cmd);
    unlink($tempoutfile);
    return($report,$fusionflag,$sublendiscflag,$commonhithash);
  } else {
    print "QAUtils::areSameGene: False alarm\n";
    unlink($tempoutfile);
    return(0,$fusionflag,$sublendiscflag);
  }
}

# Check if a gene and an IR are part of the same gene
# $relor can be GENEIR or IRGENE and denotes order on chromosome
sub areSameGeneIR {
  my ($gene,$ir,$sign,$genepbr,$irpbr,$relor)=@_;

  my $commHits=BioUtils::getCommonHits($genepbr,$irpbr,0);
  my @garr=split(/\n/,$genepbr);
  my @irarr=split(/\n/,$irpbr);

  my $gsbs={}; my $gses={}; my $isbs={}; my $ises={};

  foreach my $hit (@garr) {
    next if ($hit eq '' || $hit=~/^Report details/);
    my @hitdata=split(/\t/,$hit);
    if (exists $commHits->{$hitdata[0]}) {
      $gsbs->{$hitdata[0]}=$hitdata[5];
      $gses->{$hitdata[0]}=$hitdata[6];
    }
  }
  foreach my $hit (@irarr) {
    next if ($hit eq '' || $hit=~/^Report details/);
    my @hitdata=split(/\t/,$hit);
    if (exists $commHits->{$hitdata[0]}) {
      $isbs->{$hitdata[0]}=$hitdata[5];
      $ises->{$hitdata[0]}=$hitdata[6];
    }
  }
  my $numsanehits=0; my $sanehits={};
  foreach my $commsub (keys %{ $commHits }) {
    
      if (($sign eq '+' && $relor eq 'GENEIR')||($sign eq '-' && $relor eq 'IRGENE')) {
	if ($gses->{$commsub}<$isbs->{$commsub} && $gses->{$commsub}<$ises->{$commsub}) {
	  $numsanehits++; $sanehits->{$commsub}=1;
	}
      } elsif (($sign eq '+' && $relor eq 'IRGENE')||($sign eq '-' && $relor eq 'GENEIR')) {
	if ($ises->{$commsub}<$gsbs->{$commsub} && $ises->{$commsub}<$gses->{$commsub}) {
	  $numsanehits++; $sanehits->{$commsub}=1;
	}
      }
  }
  if ($numsanehits>0) {
    return(1,$sanehits);
  } else {
    return(0,$sanehits);
  }
}

# Prune broken gene set based on discords
sub pruneBGset {
  my ($bgarr,$discords)=@_; my $newbgsets={};

  if (scalar(keys %{ $discords })==0) {
    $newbgsets->{join(',',@{ $bgarr })}=1;
    return($newbgsets);
  }

  my $bgstring=join(',',@{ $bgarr }); my $breakpoints={}; my @nndiscords;
  #print "pruneBGset: BGstring=$bgstring\n";
  foreach my $dset (keys %{ $discords }) {
    #print "pruneBGset: Dset=$dset\n";
    if ($bgstring=~/$dset/) {
      $dset=~/(.+),(.+)/; $breakpoints->{$1}=1;
    } else {
      #print "pruneBGset: Discordant non-neighboring pair $dset\n";
      push @nndiscords,$dset;
    }
  }
  #print "pruneBGset: Breakpoints=",join(' ',keys %{ $breakpoints }),"\n";
  my $currset='';
  for (my $i=0; $i<@{ $bgarr }; $i++) {
    next if ($bgarr->[$i]=~/-/);
    if ($currset ne '') { $currset.=",$bgarr->[$i]"; }
    else { $currset="$bgarr->[$i]"; }
    if (exists $breakpoints->{$bgarr->[$i]}) {
      if ($currset ne '') { $newbgsets->{$currset}=1; $currset=''; }
    }
  }
  if ($currset ne '') { $newbgsets->{$currset}=1; }
  # Check if the nndiscords still exist within the fragmented sets
  foreach my $key (keys %{ $newbgsets }) {
    foreach my $nnd (@nndiscords) {
      $nnd=~/(.+),(.+)/; my ($g1,$g2)=($1,$2);
      if ($key=~/$g1/ && $key=~/$g2/) {
	delete $newbgsets->{$key};
      }
    }
  }
  #print "pruneBGset: New BG sets=",join(' ',keys %{ $newbgsets }),"\n";
  return($newbgsets);
}

# Extract sequence from GB or EMBL file
sub getARTFSequence ($) {
  open (ARTF,$_[0])
    or die "QAUtils::getARTFSequence: Couldn't open source artemis file $_[0]\n";
  my $sflag=0; my $sequence='';
  while (<ARTF>) {
    chomp($_); my $line=$_;
    if ($line=~m/^SQ/ || $line=~m/^ORIGIN/) {
      $sflag=1; next;
    }
    if ($sflag) {
      $line=~s/ |[0-9]|\///g;
      $sequence=$sequence.$line;
    }
  }
  close(ARTF);
  return($sequence);
}

# Extract seq from fa file
sub getFASequence {
  open (FAF,$_[0])
    or die "QAUtils::getFASequence: Couldn't open source fasta file $_[0]\n";
  print "getFASequence: Extracting sequence from file $_[0]\n";
  my $seq='';
  while (<FAF>) {
    chomp($_); my $line=$_;
    next if ($line=~/^>/);
    $seq.=$line;
  }
  close(FAF);
  return($seq);
}

###############################################################################
# isShortGene: 	Subroutine to determine from intergenic region hits and an
# 		undecided long/short gene if the said gene is short
# Arguments:	ARG1: ID of gene
# 		ARG2: Hash containing candidate long/short genes
# 		ARG3: Hash containing blast hits of all intergenic regions
# 		ARG4: Hash containing blast hits of all predicted genes
#		ARG5: ID of the intergenic region around which ARG1 is located
# Returns:	1, if the gene is determined as short,
# 		0, otherwise.
# Author: Amrita Pati, Email: apati@lbl.gov
# Last Updated: 06/18/2008
###############################################################################
sub isShortGene ($$$$$) {
  my $gene=$_[0]; my $candhash=$_[1]; my $inthash=$_[2]; my $allhash=$_[3];
  my $intid=$_[4];
  #print "QAUtils::isShortGene: Exploring gene $gene,$intid\n";
  if (defined $inthash->{$intid} && defined $allhash->{$gene}) {
    my @arr1=split(/\t/,$inthash->{$intid});
    my @arr2=split(/\t/,$allhash->{$gene});
    for (my $i=1; $i<@arr1; $i++) {
      for (my $j=1; $j<@arr2; $j++) {
        if ($arr1[$i] eq $arr2[$j]) {
	  #print "QAUtils::isShortGene: Found match between gene hit $arr2[$j] and intergenic region hit $arr1[$i]\n";
	  return(1);
        }
      }
    }
  }
  return(0);
}

###############################################################################
# isLongGene: 	Subroutine to determine from location of genes and an
# 		undecided long/short gene if the said gene is long
# Arguments:	ARG1: ID of gene
# 		ARG2: Hash containing start positions of all genes
# 		ARG3: Hash containing end positions of all genes
# 		ARG4: Hash containing signs of all genes
# Returns:	1, if the gene is determined as long,
# 		0, otherwise.
# Author: Amrita Pati, Email: apati@lbl.gov
# Last Updated: 06/18/2008
###############################################################################
sub isLongGene ($$$$$) {
  my $geneid=$_[0]; my $starts=$_[1]; my $ends=$_[2]; my $signs=$_[3]; my $partf=$_[4];
  my $LNbors={}; my $RNbors={};
  BioUtils::getNborFeats($partf,$LNbors,$RNbors);
  my $idlt=$LNbors->{$geneid}; my $idgt=$RNbors->{$geneid};
  
  my $neighborgene=$signs->{$geneid} eq '+'?$idlt:$idgt;
  my $promLt100=0;
  if ($signs->{$geneid} eq '+' && $signs->{$neighborgene} eq '-') {
    $promLt100=1 if ($starts->{$geneid}-$ends->{$neighborgene}<100);
  } elsif ($signs->{$geneid} eq '-' && $signs->{$neighborgene} eq '+') {
    $promLt100=1 if ($starts->{$neighborgene}-$ends->{$geneid}<100);
  }

  return($promLt100);

}

###############################################################################
# isInterruptedGene:
# 		Subroutine to determine if a gene is potentially interrupted
# Arguments:	ARG1: ID of short gene
# 		ARG2: ID of other gene
# 		ARG3: Hash of all blast hits
# 		ARG4: Hash containing details of blast hits
# 		ARG5: Hash with strand of all genes
#		ARG6: Hash with featStarts
# Returns:	1, if gene is interrupted,
# 		0, otherwise.
# Author: Amrita Pati, Email: apati@lbl.gov
# Last Updated: 06/20/2008
###############################################################################
sub isInterruptedGene ($$$$$$$) {

  my $sgene=$_[0]; my $gene=$_[1]; my $hithash=$_[2]; my $coords=$_[3];
  my $strand=$_[4]; my $featstarts=$_[5]; my $featends=$_[6];

  return(0) if ($sgene eq $gene);

  return (0) if (!exists $hithash->{$gene});
  # Warning here: Catch blank report
  my @hits1=split(/\t/,$hithash->{$sgene}); my @hits2=split(/\t/,$hithash->{$gene});
  return(0) if (@hits1<4 || @hits2<4);

  # Check if they have >=1 common hits
  my $commhits=0; my $commlist=();
  for (my $i=0; $i<@hits1; $i++) {
    for (my $j=0; $j<@hits2; $j++) {
      if ($hits1[$i] eq $hits2[$j] && $hits1[$i] ne '') {
	$commlist->[$commhits]=$hits1[$i]; $commhits++;
	#print "Found common hit $hits1[$i]\n";
      }
    }
  }
  return(0) if ($commhits<1);

  # Check if they are within 10K of each other
  return(0) if (abs($featstarts->{$sgene}-$featstarts->{$gene})>10000);

  my $sizelist=@{ $commlist };
  print "Short Gene=$sgene, Other Gene=$gene, Hits=$commhits, List size=$sizelist\n";
  my $sanealncnt=0;
  for (my $i=0; $i<@{ $commlist }; $i++) {
    my @c1=split(/\t/,$coords->{$sgene.$commlist->[$i]});
    my @c2=split(/\t/,$coords->{$gene.$commlist->[$i]});
    print "C1=@c1, C2=@c2, Key=$sgene.$commlist->[$i]\n";

    # Compare subject lengths
    return(0) if ($c1[2]<(0.9*$c2[2]-1) || $c1[2]>(1.1*$c2[2]+1));

    # Compare query sums to smaller subject length
    my $smallsub=$c1[2]>$c2[2]?$c1[2]:$c2[2];
    $sanealncnt++ if(($c1[1]+$c2[1]>(0.8*$smallsub-1))&&($c1[1]+$c2[1]<(1.2*$smallsub+1)));

    # Check 3' and 5' orientations
    if ($strand eq '+') {
      return(0) if (($c1[5]>$c2[5] && $featstarts->{$sgene}<$featstarts->{$gene})||($c1[5]<$c2[5] && $featstarts->{$sgene}>$featstarts->{$gene}));
    } else {
      return(0) if (($c1[5]>$c2[5] && $featends->{$sgene}>$featends->{$gene})||($c1[5]<$c2[5] && $featends->{$sgene}<$featends->{$gene}));
    }
  }
  if ($sanealncnt >= 0.5*scalar(@{ $commlist })) {
    print "Found interrupted gene $sgene\n";
    return(1);
  }
  return(0);

}

# Subroutine to prune the intergenic blast hits file off of no hit queries
# and results with only one hit to its own genome

sub pruneIntBlastFile ($$$$$$) {

  my ($ibrf,$ipbrf,$selfdraft,$genepbrfile,$featstrands,$iseuk)=@_;
  my $delhash={}; my $query='';
  $ipbrf=~/(.+)_(.+)/; my $pathprefix=$1;
  print "PATH prefix=$pathprefix\n";
  my $prefixfile=$pathprefix."_id.txt";

  my $genepbrs={}; my $genelist={};
  BioUtils::getPBRs($genelist,$genepbrfile,$genepbrs,1);
  my $numhitshash={}; my $intpbrs={};
  BioUtils::getPBRs($genelist,$ipbrf,$intpbrs,1);
  print "pruneIntBlastFile: Number of intergenic PBRs=",scalar(keys %{ $intpbrs }),"\n";
  foreach my $ir (keys %{ $intpbrs }) {
    # Eukaryotic change
    $numhitshash->{$ir}=BioUtils::getNumNonEukSelfHits($intpbrs->{$ir});
  }

  # Eukaryotic change
  pruneIntBlastReports ($ibrf,$selfdraft,$delhash,$genepbrs,$featstrands,$iseuk);

  my $size= keys %{ $delhash };
  print "Number of reports to discard=$size\n";

  my $newreport=''; my $thisreport=''; my $arehits=1; my $line='';
  my $blastdb=getBlastDB($prefixfile);

  open(INFILE,$ibrf) or die "Couldn't open $ibrf to read\n";
  while (<INFILE>) {
    chomp($_); $line=$_;
    if ($line=~/^BLAST/) {
      if ($arehits && $thisreport ne '') {
        print "Query=$query\n";
        # Eukaryotic change
        if (exists $delhash->{$query} || $numhitshash->{$query}==0) {
	  print "Don't include report for $query\n";
	} else { $newreport=$newreport.$thisreport; }
      }
      $arehits=1; $thisreport=''; next;
    } elsif ($line=~/^Query=\s(.+)/) {
      $query=$1;
    } elsif ($line=~m/No hits found/) { $arehits=0; }
  } continue { $thisreport.=$line."\n"; }
  close(INFILE);

  if ($arehits && $thisreport ne '' && (!(exists $delhash->{$query}))) {
    $newreport.=$thisreport;
  }

  open(OUTF,">$ibrf") or die "Couldn't open $ibrf to write\n";
  print OUTF $newreport;
  print OUTF "  Database: $blastdb";
  close(OUTF);

}

sub pruneIntBlastReports ($$$$$$) {

  my ($repfile,$match,$delhash,$genepbrs,$featStrand,$iseuk)=@_;
  my $multireport=new BPlite::Multi("$repfile");
  $repfile=~/(.+)_(.+)/; my $pathp=$1; my $idfile=$pathp."_id.txt";
  # If database is IMG related, retrieve taxon OIDs of all genomes that match the self-genome
  my $dbused=QAUtils::getBlastDB($idfile);
  my $selftaxoidstr;
  if ($dbused=~m/IMG/i) {
    #$selftaxoidstr=QAUtils::getSelfTaxonOIDs($match,$idfile);
    $selftaxoidstr=QAUtils::getSelfTaxOIDstrFromIDF($idfile);
    print "parseBlastP: Self taxon OIDs=$selftaxoidstr\n";
  } else {
    print "Unknown database used! Rest of the program may not work correctly with your Blast database. Please use the IMGnr database (available for download from GenePRIMP) and retain its naming!\n";
    exit;
  }

  while (my $report=$multireport->nextReport) {
    my $query=$report->query;
    my $querylen=$report->queryLength;
    my $database=$report->database;
    my $numhits=0; my $numselfhits=0; my $numsubjs=0; my $numselfhsps=0;
    my $numeukhits=0; my $sbjctID='';
    my @queryframes; my $numqfs=0; my @qfstarts; my @qfends;
    my $qfhash={}; my $isselfhit=0;

    # Get next subject
    while(my $sbjct = $report->nextSbjct) {
      my $subname=$sbjct->name;
      my $matches = () = $subname =~ /ref\||gb\||emb\||(..)_(\d+)_(\d+)_(\d+)/g;
      $sbjct->name=~ m/>?([^\s]*)\s([^\n]*)/;
      $sbjctID=$1; my $sbjctAnnotation=$2;
      $sbjctAnnotation=~s/\/([^\n]*)//; # Subject annotation
      $isselfhit=0;
      $numsubjs=$numsubjs+$matches;
      # Detect self-hits
      if ($sbjctID=~/(..)_(\d+)_(\d+)_(\d+)/) { # Database is IMGnr
	my ($sbtyp,$geneoid,$taxoid,$genelen)=($1,$2,$3,$4);
	if ($selftaxoidstr=~m/$taxoid/) { $isselfhit=1; $numselfhits++; }
        if ($sbtyp=~/^E|V/) { $numeukhits++; } 
      } else {
	print STDERR "parseBlastP: Subject ID not in desired format. $sbjctID, aborting!\n";
	exit;
      }
      my $sl=$sbjct->length; # Subject length
      my $hspChoice=''; my $thisubjqf=''; my $thisubjqfst=0; my $thisubjqfend=0;

      # Get next HSP
      while (my $hsp = $sbjct->nextHSP) {	
        $numhits++;
	$numselfhsps++ if ($isselfhit);
	# Retrieve Alignment Properties
	my $score=$hsp->score;
        my $bits=$hsp->bits; # Bit score
       	my $percent=$hsp->percent; # Percentage of identities
        my $p=$hsp->P; # e-value
        my $match=$hsp->match; # Number of identities
        my $positive=$hsp->positive; # Number of positives
        my $al=$hsp->length;
        my $qb=$hsp->queryBegin; # Query begin position
        my $qe=$hsp->queryEnd; # Query end position
        my $sb=$hsp->sbjctBegin; # Subject begin position
        my $se=$hsp->sbjctEnd; # Subject end position
        my $qa=$hsp->queryAlignment; # Query alignment
        my $sa=$hsp->sbjctAlignment; # Subject alignment
        my $as=$hsp->alignmentString; # Alignment string
        my $qg=$hsp->queryGaps;
        my $sg=$hsp->sbjctGaps;
	my $qf=$hsp->queryFrame;

	if (!$thisubjqf) {
	  $thisubjqf=$qf; $thisubjqfst=$qb; $thisubjqfend=$qe;
	} else {
	  my $updateflag=0;
	  foreach my $key (sort { $qfhash->{$b} <=> $qfhash->{$a} } (keys(%{ $qfhash } ))) {
	    if ($key ne $thisubjqf && $key eq $qf) { $updateflag=1; last; }
	  }
	  if ($updateflag) {
	    $thisubjqf=$qf; $thisubjqfst=$qb; $thisubjqfend=$qe;
	  }
	}
      } # HSP loop

      $queryframes[$numqfs]=$thisubjqf; $qfstarts[$numqfs]=$thisubjqfst; $qfends[$numqfs]=$thisubjqfend;
      $numqfs++;
      if (exists $qfhash->{$thisubjqf}) {
        $qfhash->{$thisubjqf}=$qfhash->{$thisubjqf}+1;
      } else {
        $qfhash->{$thisubjqf}=1;
      }

    } # Subject loop
    $queryframes[$numqfs]=$queryframes[0];
    $qfstarts[$numqfs]=$qfstarts[0]; $qfends[$numqfs]=$qfends[0];
    $numqfs++; my $diffQframes=0;
    if (@queryframes) { print @queryframes,"\n"; }
    $diffQframes=analyzeQFs(\@queryframes,\@qfstarts,\@qfends);
    print "Query=$query, Numsubjs=$numsubjs, Numhits=$numhits, Numeukhits=$numeukhits\n";
    if ((!($iseuk) && ($numsubjs==$numselfhits+$numeukhits || $numeukhits>0.5*$numhits)) || ($iseuk && $numsubjs==$numselfhits) || ($numhits == $numselfhsps)) {
      $query=~s/\s//g; $query=~/(.+)\(.+\)/; $delhash->{$1}=1;
      print "Discarding $query because of self/euk hits, numsubs=$numsubjs, numselfhits=$numselfhits, numeuks=$numeukhits\n";
    }

    if ($numsubjs==1 && $numselfhits==1) {
      $query=~/(.+)-(.+)/;
      my $lgene=$1; my $rgene=$2;
      if ($featStrand->{$lgene} eq '-') {
	my @arr=split(/\n/,$genepbrs->{$lgene});
	if (@arr==2) {
	  my @sarr=split(/\t/,$arr[1]);
	  if ($sarr[0] eq $sbjctID) {
	    print "Discarding - $query here\n";
      	    $query=~s/\s//g; $query=~/(.+)\(.+\)/; $delhash->{$1}=1;
	  }
	}
      }
      if ($featStrand->{$rgene} eq '+') {
	my @arr=split(/\n/,$genepbrs->{$rgene});
	if (@arr==2) {
	  my @sarr=split(/\t/,$arr[1]);
	  if ($sarr[0] eq $sbjctID) {
	    print "Discarding + $query here\n";
      	    $query=~s/\s//g; $query=~/(.+)\(.+\)/; $delhash->{$1}=1;
	  }
	}
      }
    } # ENd if

  } # Report loop
}

# Subroutine to do query frames analysis for BlastX hits pruning
sub analyzeQFs {

    my $queryframes=$_[0]; my $qfstarts=$_[1]; my $qfends=$_[2];
    my $diffQframes=0;

    for (my $i=0; $i<@{ $queryframes }-1; $i++) {
      if ($queryframes->[$i] != $queryframes->[$i+1]) {
        my $s1=$qfstarts->[$i]; my $e1=$qfends->[$i]; my $s2=$qfstarts->[$i+1]; my $e2=$qfends->[$i+1];
	my $shorthsplen=abs($s1-$e1)<abs($s2-$e2)?abs($s1-$e1):abs($s2-$e2);
        if ((($s1<$e1) && (($s1<$s2 && $s2<$e1 && abs($s2-$e1)>0.5*$shorthsplen)||($s1>$s2 && $s1<$e2 && abs($s1-$e2)>0.5*$shorthsplen))) || (($s1>$e1) && (($e1<$e2 && $e2<$s1 && abs($e2-$s1)>0.5*$shorthsplen)||($e1>$e2 && $e1<$s2 && abs($e1-$s2)>0.5*$shorthsplen)))) {
	  $diffQframes=1; last;
	}
        #if ($s1<$e1) { # + orient
	  #if ($s2>$e2) {
	  #  print "HSPs in inverse frames\n"; $diffQframes=1; last;
	  #}
	  #if (($s1<$s2 && $s2<$e1 && abs($s2-$e1)>0.5*$shorthsplen)||($s1>$s2 && $s1<$e2 && abs($s1-$e2)>0.5*$shorthsplen)) {
	  #  print "Diff query frames\n";
	  #  $diffQframes=1; last;
	  #}
	#} elsif ($s1>$e1) { # - orient
	  #if ($s2<$e2) {
	  #  print "HSPs in inverse frames\n"; $diffQframes=1; last;
	  #}
	  #if (($e1<$e2 && $e2<$s1 && abs($e2-$s1)>0.5*$shorthsplen)||($e1>$e2 && $e1<$s2 && abs($e1-$s2)>0.5*$shorthsplen)) {
	  #  print "Diff query frames\n";
	  #  $diffQframes=1; last;
	  #}
	#}
      }
    }
    return($diffQframes);
}

sub remIntFromShort ($$$) {

  my $lsf=$_[0]; my $ulsf=$_[1]; my $bgf=$_[2];
  my $lsgenes={}; my $ulsgenes={}; my $bgenes={};

  BioUtils::putIntoHash($lsf,1,-1,$lsgenes,"\t",1,'');
  BioUtils::putIntoHash($ulsf,1,-1,$ulsgenes,"\t",1,'');

  open (BGF,$bgf)
    or die "remIntFromShort: Couldn't open interrupted genes file\n";
  while (<BGF>) {
    chomp($_); my $line=$_;
    if ($line=~/(.+)\tshared hits with gene (.+)/) {
      my $g1=$1; my $g2=$2;
      $bgenes->{$g1}=1; $bgenes->{$g2}=1;
    }
  }
  close(BGF);

  # Now write pruned lists to the long/short genes and ls-undecided files
  open (LSF,">$lsf")
    or die "Couldn't open $lsf to write\n";
  foreach my $gene (sort keys %{ $lsgenes }) {
    if (!(exists $bgenes->{$gene})) {
      print LSF "$lsgenes->{$gene}\n";
    }
  }
  close(LSF);
  open (ULSF,">$ulsf")
    or die "Couldn't open $ulsf to write\n";
  foreach my $gene (sort keys %{ $ulsgenes }) {
    if (!(exists $bgenes->{$gene})) {
      print ULSF "$ulsgenes->{$gene}\n";
    }
  }
  close(ULSF);
}
# Subroutine to trim the list of short genes and remove from it
# all genes classified as broken genes
# ARG0: File with long/short genes
# ARG1: File with unclassified long/short genes
# ARG2: File with broken genes

sub remBrknFromShort ($$$) {

  my $lsf=$_[0]; my $ulsf=$_[1]; my $bgf=$_[2];
  my $lsgenes={}; my $ulsgenes={}; my $bgenes={};

  BioUtils::putIntoHash($lsf,1,-1,$lsgenes,"\t",1,'');
  BioUtils::putIntoHash($ulsf,1,-1,$ulsgenes,"\t",1,'');

  open (BGF,$bgf)
    or die "remBrknFromShort: Couldn't open broken genes file\n";
  while (<BGF>) {
    chomp($_); my $line=$_;
    #if($line=~/Putative broken gene:(.+) and (.+), concatenated blast report/) {
    if($line=~/Putative broken gene: (.+)/) {
      #my $g1=$1; my $g2=$2;
      #$bgenes->{$g1}=1; $bgenes->{$g2}=1;
      my $bgs=$1; my @arr=split(' ',$bgs);
      foreach my $g (@arr) { $bgenes->{$g}=1; }
    }
  }
  close(BGF);

  # Now write pruned lists to the long/short genes and ls-undecided files
  open (LSF,">$lsf")
    or die "Couldn't open $lsf to write\n";
  foreach my $gene (sort keys %{ $lsgenes }) {
    if (!(exists $bgenes->{$gene})) {
      print LSF "$lsgenes->{$gene}\n";
    }
  }
  close(LSF);
  open (ULSF,">$ulsf")
    or die "Couldn't open $ulsf to write\n";
  foreach my $gene (sort keys %{ $ulsgenes }) {
    if (!(exists $bgenes->{$gene})) {
      print ULSF "$ulsgenes->{$gene}\n";
    }
  }
  close(ULSF);
}

# Subroutine for extra try-out filters for the list of short genes
# Implemented 02/26
# If the longest hit is longer than 3 times the second shortest subject,
# then prune
# ARG0: File with long/short genes
# ARG1: File with filtered PBRs
sub extraShortGenesFilter {
 
  my $lsfile=$_[0]; my $fpbrs=$_[1];
  my $lsgenes={}; my $pbrhash={};

  BioUtils::putIntoHash($lsfile,1,-1,$lsgenes,"\t",1,'');
  BioUtils::getPBRs($lsgenes,$fpbrs,$pbrhash,0);
  
  foreach my $gene (sort keys %{ $lsgenes }) {
    if (!exists ($pbrhash->{$gene})) {
      delete $lsgenes->{$gene};
      print "extraShortGenesFilter: No PBR for gene $gene\nExiting ...\n";
    }
    my @arr=split(/\n/,$pbrhash->{$gene}); my @slens;
    next if (!($arr[0]=~/WARNING/));
    foreach my $line (@arr) {
      next if ($line=~/^Report details/);
      my @larr=split(/\t/,$line);
      push @slens, $larr[2];
    }
    my @sorted = sort { $a <=> $b } @slens;
    if ($sorted[@sorted-1] > 3*$sorted[1]) {
      print join(" ",@sorted), "\n";
      delete $lsgenes->{$gene};
    }
  }

  open(OUTF,">$lsfile")
    or die "Couldn't open file $fpbrs to write\n";
  foreach my $gene (sort keys %{ $lsgenes }) {
    print OUTF $lsgenes->{$gene},"\n";
  }
  close(OUTF);

}

# Subroutine to eliminate suspicious hits from the parsed BR
# and to retain the top 10 (or less) hits thereafter
# ARGV0: Filtered parsed BR
# ARG1: Self draft genome ID

sub filterSuspHits ($$$$) {
  my ($fpbr,$selfdraft,$iseuk,$ugf)=@_;
  my $pbrhash={}; my $genehash={};
  my $thisreport=''; my $allreports=''; my $hitscnt=0;
  open(UGF,">>$ugf")
    or die "filterSuspHits: Couldn't open $ugf to append to\n";

  BioUtils::getPBRs($genehash,$fpbr,$pbrhash,1);
  foreach my $gene (sort keys %{ $pbrhash }) {
    my $thispbr=$pbrhash->{$gene}; chomp($thispbr); my @arr=split(/\n/,$thispbr);
    my $numselfhits=0; my $selfhitidx=-1; my $numeukhits=0;
    my @pdbhitidxs;
    $arr[0]=~/Report details: Query=(.+)\s\(.+\)\s,\sLength=(\d+),\sDatabase=.+/;
    my $seqlen=$2;
    for (my $i=1; $i<@arr; $i++) {
      my $pushflag=0;
      my @subarr=split(/\t/,$arr[$i]);
      if ($subarr[16]==1) {
	$numselfhits++; $selfhitidx=$i; $pushflag=1;
      } elsif ($subarr[15]==1) {
        $numeukhits++;
      } elsif ($arr[$i]=~/^pdb/) {
        push @pdbhitidxs, $i; $pushflag=1;
      }
      if($subarr[11]=~/e\-\d+/) { }
      elsif($subarr[11]>1 && $seqlen>=100)  { push (@pdbhitidxs, $i) if (!$pushflag); }
    }
    my $j=0;
    if ($numselfhits==1) { splice (@arr,$selfhitidx,1); $j++; }
    for (my $i=0; $i<@pdbhitidxs; $i++) {
      splice (@arr,$pdbhitidxs[$i]-$j,1); $j++;
    }
    if ($numeukhits==@arr-1 && !($iseuk)) {
      # This means that all remaining hits are eukaryotic hits and the org in question is not a euk
      print UGF "$gene\tSEMIUNIQUE\n";
    } elsif ($arr[0]=~/WARNING: Hits derived from second blast run/ && $numeukhits>=2 && !($iseuk)) {
      # Genes with hits from second round of blast with 2 or more hits to eukaryotic proteins
      print UGF "$gene\tSEMIUNIQUE\n";
    } elsif (@arr-1<3) {
      # Less than 3 hits left after all filtering
      print UGF "$gene\tSEMIUNIQUE\n";
    } else{
      $thisreport=$arr[0];
      my $min=@arr<11?@arr-1:30;
      for (my $i=1; $i<=$min; $i++) {
	$thisreport.="\n$arr[$i]";
      }
      $allreports.=$thisreport."\n";
    }
  }
  $allreports=~s/^\n//g;
  open(FR,">$fpbr")
    or die "Couldn't open filtered parsed BR $fpbr to write\n";
  print FR $allreports;
  close(FR);
  close(UGF);
  return; 
}

# Subroutine to get the number of fully aligned hits in a PBR
sub getNumFullAlnHits ($) {
  my $pbr=$_[0];
  my @arr=split(/\n/,$pbr); my $numfahits=0;
  shift(@arr);
  my $limit=10<scalar(@arr)?10:scalar(@arr);
  for (my $i=0; $i<$limit; $i++) {
    my @sarr=split(/\t/,$arr[$i]);
    my $qb=$sarr[3]; my $sb=$sarr[5]; my $pi=$sarr[8]; my $bs=$sarr[7];
    if ($qb<=10 && $sb<=10 && abs($qb-$sb)<=5) { $numfahits++; }
  }
  return($numfahits);
}

# Subroutine to convert a hash to an array
sub Hash2Arr ($) {
  my $hash=$_[0]; my $arr=(); my $i=0;
  while (my($key,$value)=each %{ $hash }) {
    $arr->[$i]=$value; $i++;
  }
  return($arr);
}

# Subroutine to fix format of EMBL file
sub fixEMBLfile {
  my $emblf=$_[0];
  open (EF, $emblf) or die "fixEMBLfile: Couldn't open EMBL file $emblf to read\n";

  my $done=0; my $report="";
  while (<EF>) {
    my $line=$_;
    next if ($line=~/^\s*$/);
    if ($line=~/^ID/) {
      $line.="XX\n";
    }
    if ((!$done) && $line=~/^FT/) {
      $line="FH\nXX\n".$line; $done=1;
    }
    $report.=$line;
  } close(EF);

  open (EFW, ">$emblf") or die "fixEMBLfile: Couldn't open EMBL file $emblf to write\n";
  print EFW $report;
  close(EFW);

  return;
}

# Subroutine to separate broken genes from interrupted
sub getBrokenFromInterrupted {
  my ($igfile,$bgfile,$partf,$seq,$filtpbrsfile,$bgalnfile,$aaf,$selfdraft)=@_;
  my $LNbors={}; my $RNbors={}; my $genepbrs={}; my $igstr='';
  my $genes={}; my $protseqs={}; my $genestarts={}; my $geneends={};
  BioUtils::getNborFeats($partf,$LNbors,$RNbors);
  BioUtils::getPBRs($genes,$filtpbrsfile,$genepbrs,1);
  BioUtils::getPBRs($genes,$aaf,$genepbrs,1);
  BioUtils::putIntoHash($partf,1,8,$protseqs,"\t",1,'');
  BioUtils::putIntoHash($partf,1,4,$genestarts,"\t",1,'');
  BioUtils::putIntoHash($partf,1,5,$geneends,"\t",1,'');

  my $bgs={};
  open(BGFR,"$bgfile")
    or die "getBrokenFromInterrupted: Couldn't open $bgfile to read\n";
  while(<BGFR>) {
    chomp($_); my $line=$_;
    if ($line=~/Putative broken gene:(\s)?([A-Za-z0-9_\-\s]+)(, concatenated blast report)?/) {
      my $bg=$2; $bgs->{$bg}=1;
    }
  }
  close(BGFR);

  open(IGF,$igfile)
    or die "getBrokenFromInterrupted: Couldn't open $igfile to read\n";
  open(BGF,">>$bgfile")
    or die "getBrokenFromInterrupted: Couldn't open $bgfile to write\n";
  while (<IGF>) {
    chomp($_); my $line=$_;
    $line=~/(.+)\tshared hits with gene (.+)/;
    my ($gene1,$gene2)=($1,$2);
    if ($gene1 eq $RNbors->{$gene2} && (!isIntBroken("$gene2 $gene1",$bgs))) {
      my $sequence=Parser::revComp(substr($seq,$genestarts->{$gene2}-1,$geneends->{$gene1}-$genestarts->{$gene2}+1));
      my ($ppreport,$preport)=($genepbrs->{$gene2},$genepbrs->{$gene1});
      my $ans=QAUtils::areSameGene($gene2,$gene1,$ppreport,$preport,$sequence,$bgalnfile,$selfdraft,$protseqs->{$gene2},$protseqs->{$gene1},$genestarts->{$gene2},$genestarts->{$gene1});
      if ($ans ne '0') {
        print BGF "Putative broken gene: $gene2 $gene1\n" if (!isIntBroken("$gene2 $gene1",$bgs));
      }
    } elsif ($gene1 eq $LNbors->{$gene2} && (!isIntBroken("$gene1 $gene2",$bgs))) {
      my $sequence=substr($seq,$genestarts->{$gene1}-1,$geneends->{$gene2}-$genestarts->{$gene1}+1);
      my ($ppreport,$preport)=($genepbrs->{$gene1},$genepbrs->{$gene2});
      my $ans=QAUtils::areSameGene($gene1,$gene2,$ppreport,$preport,$sequence,$bgalnfile,$selfdraft,$protseqs->{$gene1},$protseqs->{$gene2},$genestarts->{$gene1},$genestarts->{$gene2});
      if ($ans ne '0') {
        print BGF "Putative broken gene: $gene1 $gene2\n" if (!isIntBroken("$gene1 $gene2",$bgs));
      }
    } else {
      $igstr.=$line."\n";
    }
  }
  close(IGF); close(BGF);

  open (IGFW,">$igfile")
    or die "getBrokenFromInterrupted: Couldn't open $igfile to write\n";
  print IGFW $igstr;
  close(IGFW);

}

# Subroutine to determine if a given interrupted gene is part of a broken gene
sub isIntBroken {
  my ($ig,$bghash)=@_;
  foreach my $bgset (sort keys %{ $bghash }) {
    if ($bgset=~/$ig/) { return(1); }
  }
  return(0);
}

# Subroutine to check if a PBR consists of hits to proteins that consist of repeat units
sub hasHits2RptProts {
  my $pbr=$_[0]; my @arr=split(/\n/,$pbr);
  # First, separate the hits into PBR clusters
  my $pbrclusters={}; my $rptflag=0;
  foreach my $hit (@arr) {
    my @harr=split(/\t/,$hit);
    if (exists $pbrclusters->{$harr[0]}) {
      $pbrclusters->{$harr[0]}=$pbrclusters->{$harr[0]}."\n".$hit;
      $rptflag=1;
    } else {
      $pbrclusters->{$harr[0]}=$hit;
    }
  }
  if (!$rptflag) { return(0); }

  # Now evaluate each cluster to see if there is a rpt protein involved
  foreach my $sub (keys %{ $pbrclusters }) {
    my @parr=split(/\n/,$pbrclusters->{$sub});
    next if (scalar(@parr)==1);
    for (my $i=0; $i<scalar(@parr); $i++) {
      my @harr1=split(/\t/,$parr[$i]);
      my ($qs1,$qe1,$ss1,$se1)=($harr1[3],$harr1[4],$harr1[5],$harr1[6]);
      if ($qs1>$qe1) { my $temp=$qs1; $qs1=$qe1; $qe1=$temp; }
      for (my $j=$i+1; $j<scalar(@parr); $j++) {
        my @harr2=split(/\t/,$parr[$j]);
        my ($qs2,$qe2,$ss2,$se2)=($harr2[3],$harr2[4],$harr2[5],$harr2[6]);
        if ($qs2>$qe2) { my $temp=$qs2; $qs2=$qe2; $qe2=$temp; }
	# Now check if different regions on the query map to the same region
	# on the subject
	my ($subol,$qol)=(0,0);
	if (($qs1<=$qs2 && $qe1>=$qe2)||($qs2<=$qs1 && $qe2>=$qe1)||($qs1<=$qs2 && $qe1>=$qs2)||($qs1<=$qe2 && $qe1>=$qe2)) {
	  if (!(($ss1<=$ss2 && $se1>=$se2)||($ss2<=$ss1 && $se2>=$se1)||($ss1<=$ss2 && $se1>=$ss2)||($ss1<=$se2 && $se1>=$se2))) {
	    return(1);
	  }
	}
      }
    }
  }
  return(0);
}

# Subroutine to exclude fusion genes before tagging as pseudo
sub removeFusionGenes {
  my ($pbr,$blasttype)=@_; my @arr=split(/\n/,$pbr);
  my $fusiongenes={}; my $newpbr='';
  foreach my $hit (@arr) {
    next if ($hit=~/^Report details/);
    my @harr=split(/\t/,$hit);
    my $sub=''; my $qlen=$harr[1]; 
    if ($harr[0]=~/(.+)\.(.+)/) { $sub=$1; }
    else { $sub=$harr[0]; }
    if ($blasttype eq 'BLASTP') { $qlen=$qlen*3; }
    if (exists $fusiongenes->{$sub}) { next; }
    my $isfg=isFusionGene($sub,$qlen);
    if ($isfg==1) {
      $fusiongenes->{$sub}=1; next;
    } elsif ($isfg==0) {
      $newpbr=$newpbr eq ''?$hit:$newpbr."\n".$hit; next;
    } elsif ($isfg==-1) {
      next;
    }
  }
  return($newpbr);
}

# Subroutine to examine if a given gene is a fusion gene
# Returns: 1 if it is, 0 if it is not, -1 if it cannot find the gene,
# or finds >1 geneoid for that accession
sub isFusionGene {
  my ($sub,$genelen)=@_;

  my ($geneoid,$subgenelen);
  if ($sub=~/^(.+)_(\d+)_(\d+)_(\d+)$/) {
    $geneoid=$2; $subgenelen=$4;
  } else {
    print "isFusionGene: Unknown database used! Subject ID=$sub not in desired format *_*_*_*. The rest of the program will not work correctly with your Blast database. Aborting.\n";
    exit;
  }

  my $careabtfusion=1;
  # Now check length of the gene to see whether it is about the same length
  # as the query gene, if not we don't care whether the gene is a fusion gene
  if (!($subgenelen) || $subgenelen>=2*$genelen) {
    $careabtfusion=0;
  }

  if ($careabtfusion) {
    my $fusionfile='/house/homedirs/a/apati/GeneQA/Perl/fusiongenes.txt';
    my $grepres=`grep $geneoid $fusionfile`; chomp($grepres);
    if ($grepres=~/^\s*$/) {;}
    else { return(1); }
  }
  return(0);
}

# getBGstr: Get the broken gene string given a region and a gene to be added to it
sub getBGstr {
  my ($region,$addgene,$LNbors,$RNbors)=@_;
  $addgene=~s/,/ /g;
  my @rgarr=split(',',$region);
  my $genesonly='';
  foreach my $rg (@rgarr) {
    if ($rg!~/-/) {
      if ($genesonly eq '') {
        if ($addgene=~/$LNbors->{$rg}/) {
	  $genesonly=$addgene.' '.$rg;
	} elsif ($addgene=~/$RNbors->{$rg}/) {
	  $genesonly=$rg.' '.$addgene;
	} else { $genesonly=$rg; }
      } else {
	if ($addgene=~/$LNbors->{$rg}/) {
	  $genesonly.=" $addgene $rg";
	} elsif ($addgene=~/$RNbors->{$rg}/) {
	  $genesonly.=" $rg $addgene";
	} else { $genesonly.=" $rg"; }
      }
    }
  }
  return($genesonly);
}

# getSGEcoords: Get start/end of a gene which has undergone extension
sub getSGEcoords {
  my ($gene,$sgefile,$orient)=@_;
  my ($newstart,$newend)=(0,0);
  open(SGF,$sgefile)
    or die "QAUtils::getSGEcoords: Couldn't open $sgefile to read\n";
  while (<SGF>) {
    my $line=$_; chomp($line);
    next if ($line!~/$gene/);
    my @arr=split(/\t/,$line);
    next if ($arr[1]=~/FAILED|NOSTART/);
    $arr[0]=~/(.+):(.+)/;
    my $thisgene=$2;
    next if ($thisgene ne $gene);
    my $startstr=$arr[2];
    if ($startstr=~/(\d+) (.+)/) {
      my $jstr=$2;
      $jstr=~s/join|complement|\(|\)|\s//g;
      my @jarr=split(",",$jstr);
      $jarr[0]=~/(\d+)\.\.(\d+)/; $newstart=$1;
      $jarr[@jarr-1]=~/(\d+)\.\.(\d+)/; $newend=$2;
    } else {
      $newstart=$arr[2]; $newend=$arr[4];
    }
  }
  close(SGF);
  return($newstart,$newend);
}

# splitIR: Subroutine to split an intergenic region into two when a stretch
# of 100 or more consecutive Ns is present
# Note: Algorithm comes here only if such a stretch of Ns is present,
# 	so the case of no 100+ N stretches being there doesn't apply
sub splitIR {
  my ($seq, $intcnt, $intname, $intlen, $intstart, $intend, $outfile)=@_;
  
  my (@intstarts,@intends,@intseqs);

  print "Inside splitIR\n";
  my $nflag=0; my @nstarts; my @nends; my $nscnt=-1;
  my $iseq=substr($seq,$intstart,$intend-$intstart+1);
  for (my $x=0; $x<length($iseq)-100; $x++) {
    my $ch=substr($iseq,$x,1);
    if ($ch eq 'N' or $ch eq 'n') {
      if ($nflag==0) {
	$nflag=1; $nscnt++;
	$nstarts[$nscnt]=$x;
      }
    } else {
      if ($nflag==1) {
	$nflag=0;
	$nends[$nscnt]=$x;
      }
    }
  }

  # At least one contig boundary is def. present
  my $subintcnt=1; my $lastnend=0;
  #print "splitIR: Nstarts=",join(' ',@nstarts)," Nends=",join(' ',@nends),"\n";
  if (@nstarts and @nends) {
    if (scalar(@nstarts)!=scalar(@nends)) {
      print "splitIR: Something went wrong in recording nstarts and nends\n";
      exit;
    }
    # First fragment
    if ($nends[0]-$nstarts[0]+1>=100) { # Indicates a contig boundary
      my $thstart=$intstart; my $thend=$intstart+$nstarts[0]-1; my $thintlen=$thend-$thstart+1;
      my $thisseq=substr($seq,$thstart,$thend-$thstart+1);
      #print "Thstart=$thstart, Thend=$thend, Thisintlen=$thintlen, subintcnt=$subintcnt\n";
      if ($thintlen>=60) {
        open (OUTF,">>$outfile")
          or die "splitIR: Couldn't open output file $outfile\n";
        print OUTF "INT$intcnt($subintcnt)\t$intname($subintcnt)\t$thintlen\t$thstart\t$thend\t$thisseq\n";
        print "splitIR:INT$intcnt($subintcnt)\t$intname($subintcnt)\t$thintlen\t$thstart\t$thend\t$thisseq\n";
        close (OUTF);
        $subintcnt++;
      }
      $lastnend=$nends[0];
    }
    # Middle fragments
    for (my $idx=1; $idx<@nstarts; $idx++) {
      if ($nends[$idx]-$nstarts[$idx]+1>=100) { # Indicates contig boundary
	my $thstart=$intstart+$lastnend+1; my $thend=$intstart+$nstarts[$idx]-1; my $thintlen=$thend-$thstart+1;
	my $thisseq=substr($seq,$thstart,$thend-$thstart+1);
	if ($thintlen>=60) {
          open (OUTF,">>$outfile")
            or die "splitIR: Couldn't open output file $outfile\n";
          print OUTF "INT$intcnt($subintcnt)\t$intname($subintcnt)\t$thintlen\t$thstart\t$thend\t$thisseq\n";
          close (OUTF);
          $subintcnt++;
	}
	$lastnend=$nends[$idx];
      }
    }
    # Last fragment
    my $thstart=$intstart+$lastnend+1; my $thend=$intend; my $thintlen=$thend-$thstart+1;
    my $thisseq=substr($seq,$thstart,$thend-$thstart+1);
    if ($thintlen>=60) {
      open (OUTF,">>$outfile")
        or die "splitIR: Couldn't open output file $outfile\n";
      print OUTF "INT$intcnt($subintcnt)\t$intname($subintcnt)\t$thintlen\t$thstart\t$thend\t$thisseq\n";
      close (OUTF);
    }
  }
}

# getGenes4ManInsp
# Create the comparison file, extract genes for manual inspection
# and create HTML report
sub getGenes4ManInsp {
  my ($jobdir,$jobid,$origfile,$origfiletype)=@_;

  my $qaedfile="$jobdir/$jobid"."_autoQAed.gbk";
  my $comparefile="$jobdir/$jobid"."_comparisons.txt";
  my $brfile="$jobdir/$jobid"."_BR1.bo";
  my $ibrfile="$jobdir/$jobid"."_BRIntergenic.bo";
  my $ibrfile2="$jobdir/$jobid"."_BRIntergenic.2.bo";

  my $gns={}; my $igs={}; my $gbrs={}; my $igbrs={};
  BioUtils::getBRsplain($gns,$brfile,$gbrs,1);
  BioUtils::getBRsplain($igs,$ibrfile,$igbrs,1);
  BioUtils::getBRsplain($igs,$ibrfile2,$igbrs,1);

  my $compcmd="/house/homedirs/a/apati/GeneQA/Perl/IMGRedux/Compare2way.pl $origfile $origfiletype $qaedfile EMBL $comparefile LONG";
  system($compcmd);
  my @allgenes;

  my $scangenes=0;
  open (CMPFILE,$comparefile)
    or die "getGenes4ManInsp: Couldn't open $comparefile to read\n";
  while (<CMPFILE>) {
    my $line=$_; chomp($line);
    if ($line=~/^Genes tagged: For manual analysis/) {
      $scangenes=1; next;
    } elsif ($line=~/^\s*$/) {
      $scangenes=0; next;
    } elsif ($scangenes && $line=~/File 2: (.+)/) {
      my $gs=$1; my @garr=split(' ',$gs);
      push @allgenes,@garr;
    }
  }
  close (CMPFILE);
  
  print "All genes=",join(' ',@allgenes),"\n";

  my $reportstring='';
  my $htmlfile="$jobdir/$jobid"."_comparisons.html";
  open(HTMF,">$htmlfile")
    or die "getGenes4ManInsp: Couldn't open $htmlfile to write\n";
  print HTMF "<html>\n";
  print HTMF "<head></head>\n";
  print HTMF "<body>\n";
  print HTMF "<font face=\"courier\">\n";
  print HTMF "<ol>\n";
  foreach my $g (sort @allgenes) {
    print HTMF "<a name=\"${g}list\">\n";
    print HTMF "<li><a href=\"#$g\">$g</a>\n";
    $reportstring.="<a name=\"$g\">\n";
    $reportstring.="<h4>$g</h4>\n";
    my $thisbr=$gbrs->{$g}; $thisbr=~s/\n/<BR>/g; $thisbr=~s/ /&nbsp;/g;
    $thisbr=~s/&nbsp;&nbsp;<BR>\n/<BR>\n/g;
    $reportstring.=$thisbr;
    $reportstring.="<a href=#${g}list>Back</a>\n";
    $reportstring.="\n<br><hr><br>\n";
  }
  print HTMF "</ol>\n";
  print HTMF $reportstring;
  print HTMF "</font>\n";
  print HTMF "</body>\n</html>";
  close(HTMF);

}

1;
