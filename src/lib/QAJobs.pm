package QAJobs;

# Author: Amrita Pati, Genome Biology JGI
# Email: apati@lbl.gov

use strict;
use GeneticCode;
use BPlite;
use QAUtils;
use Parser;
use BioUtils;
use Param;
use SGECluster;

###############################################################################
# runBlastOnCluster: 	Subroutine to run blast on a set of predicted CDSs
# 			using the cluster
# Arguments:	ARG0: File with CDSs and sequences: Typically the output of
# 		Parser::parseArtemis
#		ARG1: Column containing ORF identifier (column # starts with 1)
#		ARG2: Column containing sequence (column # start with 1)
#		ARG3: Name of Fasta file for blast input, to be generated
#		ARG4: Name of formatted blast output file, to be generated
#		ARG5: Blast string with options
#		ARG6: Pointer to hash containing IDs of sequences to be used as
#			input. Optional
#		ARG7: Column containing type, optional
#		ARG8: String to filter type by, reqd if ARG7 is specified
# Author: Amrita Pati, Email: apati@lbl.gov
# Last Updated: 01/13/2009
###############################################################################
sub runBlastOnCluster {
  
  my $ididx=$_[1]-1; my $seqidx=$_[2]-1;
  my $parsedArtFile=$_[0];
  $parsedArtFile=~/(.+)_(.+)/; my $pathprefix=$1;
  print "PATH prefix=$pathprefix\n";
  my $prefixfile=$pathprefix."_id.txt";
  my $idprefix="";
  if (exists $_[6] || exists $_[7] || exists $_[8]) {
    QAUtils::getIDprefix($prefixfile);
    print "ID prefix=$idprefix\n";
  }
  my $blastdb=QAUtils::getBlastDB($prefixfile);

  open(INFILE,$parsedArtFile)
    or die "QAJobs::runBlastOnCluster: Couldn't open input file $_[0] to read\n";
  
  # create temporary FASTA input file for blast
  print "QAJobs::runBlastOnCluster: Preparing blast input ... \n";
  my $fafile=$_[3];
  open (OUTF,">$fafile")
    or die "QAJobs::runBlastOnCluster: Couldn't open temporary file $fafile to write sequences\n";
  my $idlist=$_[6] if (exists $_[6] && $_[6] ne '');
  while (<INFILE>) {
    chomp($_); my $line=$_;
    my @arr=split("\t",$line);
    #print "$arr[$ididx]\n";
    if ((!(exists $_[7]) && $arr[$ididx]=~/^$idprefix|Newfeat|RNA|ffs/) || (exists $_[7] && exists $_[8] && $arr[$_[7]-1] eq $_[8])) {
      my $sixflag=1;
      if (exists $_[6] && $_[6] ne '') {
        if (!(exists $_[6]->{$arr[$ididx]})) { $sixflag=0; }
      }
      if ($sixflag && (!($line=~/_ALREADY CURATED_/))) {
        print OUTF ">$arr[$ididx]\n","$arr[$seqidx]\n";
      }
    }
  }
  close(INFILE); close(OUTF);
  
  # blast output file
  my $blastoutfile=$_[4]; my $blaststr=$_[5];
  my $blastjob=$blaststr." -d $blastdb";
  my @arr=split('/',$pathprefix); my $jobid=$arr[@arr-1]; delete $arr[@arr-1];
  my $wdir=join('/',@arr);
  print "Working directory=$wdir\n";
  print "QAJobs::runBlastOnCluster: Submitting blast job to cluster.\n";
  SGECluster::runBlastOnCluster($wdir,$fafile,$blastjob,$blastoutfile,100,$jobid);
  print "QAJobs::runBlastOnCluster: Blast job completed ...\n";
  
}


###############################################################################
# runBlast: 	Subroutine to run blast on a set of predicted CDSs
# Arguments:	ARG0: File with CDSs and sequences: Typically the output of
# 		Parser::parseArtemis
#		ARG1: Column containing ORF identifier (column # starts with 1)
#		ARG2: Column containing sequence (column # start with 1)
#		ARG3: Name of Fasta file for blast input, to be generated
#		ARG4: Name of formatted blast output file, to be generated
#		ARG5: Blast string with options
#		ARG6: Pointer to hash containing IDs of sequences to be used as
#			input. Optional
#		ARG7: Column containing type, optional
#		ARG8: String to filter type by, reqd if ARG7 is specified
# Author: Amrita Pati, Email: apati@lbl.gov
# Last Updated: 06/03/2008
###############################################################################
sub runBlast {
  
  my $ididx=$_[1]-1; my $seqidx=$_[2]-1;
  my $parsedArtFile=$_[0];
  #print "ParsedArtFile=$parsedArtFile\n";
  $parsedArtFile=~/(.+)_(.+)/;
  my $prefixfile=$1."_id.txt";
  my $idprefix=QAUtils::getIDprefix($prefixfile);
  my $blastdb=QAUtils::getBlastDB($prefixfile);

  # What happnes if input file doesn't exist
  if (! -e $parsedArtFile) {
    system("touch $_[4]"); return;
  }

  open(INFILE,$parsedArtFile)
    or die "QAJobs::runBlast: Couldn't open input file $_[0] to read\n";
  
  # create temporary FASTA input file for blast
  print "QAJobs::runBlast: Preparing blast input ... IDprefix=$idprefix\n";
  my $fafile=$_[3];
  open (OUTF,">$fafile")
    or die "QAJobs::runBlast: Couldn't open temporary file $fafile to write sequences\n";
  my $idlist=$_[6] if (exists $_[6] && $_[6] ne '');
  while (<INFILE>) {
    chomp($_); my $line=$_;
    my @arr=split("\t",$line);
    if ((!(exists $_[7]) && $arr[$ididx]=~/^$idprefix|Newfeat|RNA|ffs/) || (exists $_[7] && exists $_[8] && $arr[$_[7]-1] eq $_[8])) {
      my $sixflag=1;
      if (exists $_[6] && $_[6] ne '') {
        if (!(exists $_[6]->{$arr[$ididx]})) { $sixflag=0; }
      }
      if ($sixflag && (!($line=~/_ALREADY CURATED_/))) {
        print OUTF ">$arr[$ididx]\n","$arr[$seqidx]\n";
      }
    }
  }
  close(INFILE); close(OUTF);
  
  # blast output file
  my $blastoutfile=$_[4]; my $blaststr=$_[5];
  my $blastjob=$blaststr." -d $blastdb -i ".$fafile.' -o '.$blastoutfile;
=pod
  $blastjob=~s/-d /-db /g;
  $blastjob=~s/-i /-query /g;
  $blastjob=~s/-o /-out /g;
=cut
  print "QAJobs::runBlast: Submitting blast job $blastjob.\n";
  system($blastjob);
  print "QAJobs::runBlast: Blast job completed ...\n";
}

###############################################################################
# parseBlastP: 	Subroutine to parse a multiple BLASTP output file
# Arguments:	ARG1: File containing blast results
# 		ARG2: Output file for parsed results
# Author: Amrita Pati, Email: apati@lbl.gov
# Last Updated: 06/02/2008
###############################################################################
sub parseBlastP {

  my ($reportfile,$outfile,$selfdraft,$dbused)=@_;
  my $iseuk=0;
  my $multireport=new BPlite::Multi("$reportfile");
  open (OUTF, ">$outfile")
    or die "QAJobs::parseBlastP: Couldn't open output file $outfile for writing";

  #print "QAJobs::parseBlastP: Parsing BLAST output, iseuk=$iseuk\n";
  my $eukarr=Param::eukGenomes();

  $reportfile=~/(.+)_(.+)/; my $pathp=$1; my $idfile=$pathp."_id.txt";
  # If database is IMG related, retrieve taxon OIDs of all genomes that match the self-genome
  if (!$dbused or $dbused==0 or $dbused==1) {
    $dbused=QAUtils::getBlastDB($idfile);
  }
  my $selftaxoidstr;
  if ($dbused=~m/IMG/i) {
    $selftaxoidstr=$selfdraft;
    #print "parseBlastP: Self taxon OIDs=$selftaxoidstr\n";
  } else {
    print "Unknown database used! Rest of the program may not work correctly with your Blast database. Please use the IMGnr database (available for download from GenePRIMP) and retain its naming!\n";
    exit;
  }

  # Get next blast report
  while (my $report=$multireport->nextReport) {

    my $query=$report->query;
    my $querylen=$report->queryLength;
    my $database=$report->database;
    print OUTF "Report details: Query=$query, Length=$querylen, Database=$database\n";

    # Get next subject
    while(my $sbjct = $report->nextSbjct) {

      $sbjct->name=~ m/>?([^\s]*)\s([^\n]*)/;
      my $sbjctID=$1;
      my $sbjctAnnotation=$2;
      #print "SubjectID=$sbjctID, SubjectName=",$sbjct->name,"SubjectAnnotation=$sbjctAnnotation\n";

      # Set self-hit flag and euk flag based on which database was used for Blast
      my $eukflag=0; my $selfhit=0;

      if ($sbjctID=~/(..)_(\d+)_(\d+)_(\d+)/) { # Database is IMGnr
	my ($sbtyp,$geneoid,$taxoid,$genelen)=($1,$2,$3,$4);
	if ($selftaxoidstr=~m/$taxoid/) { $selfhit=1; }
        if ($sbtyp=~/^E|V/) { $eukflag=1; } 
      } else {
	print STDERR "parseBlastP: Subject ID not in desired format. $sbjctID, aborting!\n";
	exit;
      }
      my $sl=$sbjct->length; # Subject length

      my $hspChoice='';

      # Get next HSP
      while (my $hsp = $sbjct->nextHSP) {	
		
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

	# Print desired values in desired format
	my $numfs=0; my $numsc=0;
	for (my $i=0; $i<length($qa); $i++) {
	  my $onechar=substr($qa,$i,1);
	  my $twochar=substr($qa,$i,2);
	  if ($twochar eq '//') {
	    $numfs++; $i++;
	  } elsif ($twochar eq "\\\\") {
	    $numfs++; $i++;
	  } elsif ($onechar eq '/') {
	    $numfs++;
	  } elsif ($onechar eq "\\") {
	    $numfs++;
	  } elsif ($onechar eq '*') {
	    $numsc++;
	  }
	}
	if (($iseuk eq '') || ($iseuk ne '' && $iseuk==$eukflag)) {
	  print OUTF "$sbjctID\t";
	  print OUTF "$querylen\t$sl\t";
	  print OUTF "$qb\t$qe\t$sb\t$se\t";
	  print OUTF "$bits\t$percent\t$match\t$positive\t$p\t";
	  if ($numfs>0) { print OUTF "FRAMESHIFT\t"; }
	  else { print OUTF "NONE\t"; }
	  if ($numsc>0) { print OUTF "STOPCODON\t"; }
	  else { print OUTF "NONE\t"; }
	  print OUTF "$numfs,$numsc\t";
	  print OUTF "$eukflag\t$selfhit\n";
	}
      }
    }
  }
  close(OUTF);
}

###############################################################################
# filterBlast:	Subroutine to filter blast results based on the kind of HSPs
# 		in the hits. If edges connecting high scoring pairs cross,
# 		the gene is added to the list of ambiguous genes
# Arguments:	ARG1: File containing parsed blast results
#		ARG2: File to contain list of ambiguous genes
#		ARG3: File to contain parsed blast reports for remaining genes
# Author: Amrita Pati, Email: apati@lbl.gov
# Last Updated: 06/05/2008
###############################################################################
sub filterBlast ($$$) {
  open (BFILE,$_[0])
    or die "Couldn't open blast input file\n";
  open (AFILE,">$_[1]")
    or die "Couldn't open output file of ambiguous alignments\n";
  open (FFILE,">$_[2]")
    or die "Couldn't open output file of good alignments\n";

  my $line=''; my $prevline=''; my $hsphash={}; my $thissbjct=''; my $prevsbjct='';
  my $numhsps=1; my $ambigreport=0; my $thisreport=''; my $numintersects=0;
  my $fullreport='';

  while (<BFILE>) {
    chomp($_); $line=$_;
    if ($line=~/^Report/) {
      print $line,"\n";
      if ($prevline ne '') {
        if ($numhsps>1) {
	  $ambigreport=QAUtils::findIntersections($hsphash,$numhsps);
	  if ($ambigreport==-1) {
	    $numintersects++;
	  } else {
	    $thisreport=$thisreport.$hsphash->{$ambigreport}."\n";
	  }
        } elsif ($numhsps==1) {
	  $thisreport=$thisreport.$prevline."\n";
	}
	if ($numintersects<3) {
	  print FFILE $thisreport;
	  print "QAJobs::filterBlast: Only one intersection\n" if ($numintersects==1);
	} elsif ($numintersects>=3) {
	  print AFILE $fullreport;
	}
	$ambigreport=0; $thisreport=''; $prevsbjct=''; $thissbjct=''; $numhsps=1;
	$hsphash={}; $numintersects=0; $fullreport='';
      } else { next; }
    } else {
      my @arr=split(/\t/,$line);
      $thissbjct=$arr[0];
      if ($thissbjct eq $prevsbjct) {
	$numhsps++;
        $hsphash->{$numhsps}=$line;
      } else {
        if ($numhsps==1) {
	  $thisreport=$thisreport.$prevline."\n";
	} elsif ($numhsps>1) {
	  $ambigreport=QAUtils::findIntersections($hsphash,$numhsps);
	  $thisreport=$thisreport.$hsphash->{$ambigreport}."\n" if($ambigreport!=-1);
	  $numintersects++ if ($ambigreport==-1);
	}
        $hsphash={}; $numhsps=1;
        $hsphash->{$numhsps}=$line;
      }
      $prevsbjct=$thissbjct;
    }
  } continue {
    $prevline=$line;
    $fullreport=$fullreport.$line."\n";
  }
  if ($numhsps>1) {
    $ambigreport=QAUtils::findIntersections($hsphash,$numhsps);
    if ($ambigreport==-1) {
      $numintersects++
    } else {
      $thisreport=$thisreport.$hsphash->{$ambigreport}."\n";
    }
  } elsif ($numhsps==1) {
    $thisreport=$thisreport.$prevline."\n";
  }
  if ($numintersects<2) {
    print FFILE $thisreport;
  } elsif ($numintersects>=2) {
    print AFILE $fullreport;
  }
  close(AFILE); close(BFILE); close(FFILE);
  
}

###############################################################################
# classifyCDS: 	Subroutine to classify a CDS based on its blast report
# Arguments:	ARG1: File containing parsed blast results (I)
#		ARG2: File with all parsed blast hits that are to be used for
#		future analyses (O/I)
#		ARG3: File with long and short CDSs (O)
#		ARG4: File with putative dubious genes derived from
#		unique CDSs (O)
#		ARG5: Job ID (I)
#		ARG6: Ambiguous alignments file (O)
#		ARG7: Filtered blast output file with only one HSP
#		per SQ pair (O)
#		ARG8: File with unique genes, genes without hits
#		in the first blast run (O)
#		ARG9: File with undecided long short classification (O)
#		ARG10: Self draft genome
#		ARG11: Parsed ART file
#		ARG12: 1, if job is to be run on cluster, 0 otherwise
# Author: Amrita Pati, Email: apati@lbl.gov
# Last Updated: 06/17/2008
###############################################################################
sub classifyCDS ($$$$$$$$$$$$$) {

  print "QAJobs::classifyCDS: Classifying genes based on BLAST hits\n";
  my $PBRfile=$_[0]; my $allUnfiltPBRfile=$_[1];
  my $lsfile=$_[2]; my $dgenefile=$_[3];
  my $jobid=$_[4]; my $aalfile=$_[5];
  my $filtPBRfile=$_[6]; my $ugenefile=$_[7];
  my $ulsfile=$_[8]; my $selfdraft=$_[9]; my $partf=$_[10];
  my $clusterjob=$_[11]; my $iseuk=$_[12];
  print "Part file=$partf\n";
  $partf=~/(.+)_(.+)/; my $pathp=$1;

  open(DGENEF,">$dgenefile")
    or die "QAJobs::classifyCDS: Couldn't open output file $dgenefile to write\n";

  my $blastHits={}; my $genelist={}; my $uniqueids={}; my $hitids={};
  my $genestarts={}; my $geneends={};

  BioUtils::getPBRs($genelist,$PBRfile,$blastHits,1);
  BioUtils::putIntoHash($partf,1,1,$genelist,"\t",1,'',"2:CDS");
  BioUtils::putIntoHash($partf,1,3,$genestarts,"\t",1,'',"2:CDS");
  BioUtils::putIntoHash($partf,1,4,$geneends,"\t",1,'',"2:CDS");
  print "classifyCDS: Number of genes = ",scalar(keys %{ $genelist }),"\n";

  foreach my $gene (sort keys %{ $genelist }) {
    my $gpbr='';
    if (!(exists $blastHits->{$gene})) {
      if (abs($genestarts->{$gene}-$geneends->{$gene})<=90) {
        my $dgeneclass=classifyDub($partf,$gene);
        print DGENEF $gene,"\t",$dgeneclass,"\n";
      } else {
        $uniqueids->{$gene}=1;
      }
    } else {
      $hitids->{$gene}=1;
    }
  }

  # Write unique genes to file
  open(UFILE,">$ugenefile")
    or die "QAJobs::classifyCDS: Couldn't open unique genes file $ugenefile\n";
  while (my($key,$value)=each %{ $uniqueids }) {
    print UFILE "$key\n";
  }
  close(UFILE);

  # Prepare final hits file with all hits and eliminating duplicate reports for
  # second stage hits
  print "QAJobs::classifyCDS: Combining all hits\n";
  open(ALLHITS,">$allUnfiltPBRfile")
    or die "QAJobs::classifyCDS: Couldn't open output file $allUnfiltPBRfile to write\n";
  foreach my $gene (sort keys %{ $genelist }) {
    print ALLHITS $blastHits->{$gene};
  }
  close(ALLHITS);

  # Filter hits
  print "QAJobs::classifyCDS: Filtering blast hits to eliminate intersecting HSPs\n";
  filterBlast($allUnfiltPBRfile,$aalfile,$filtPBRfile);
  print "QAJobs::classifyCDS: Eliminating suspicious hits and keeping top 10 hits\n";
  QAUtils::filterSuspHits($filtPBRfile,$selfdraft,$iseuk,$ugenefile);  # Eukaryotic change

  # Open file for long/short hits
  open(LSCDSF,">$lsfile")
    or die "QAJobs::classifyCDS: Couldn't open output file $lsfile to write\n";
  # Open file for undecided long/short hits
  open (UDF, ">$ulsfile")
    or die "Couldn't open file $ulsfile to write undecided long/short hits to\n";
  # Open unique genes file
  open(UGENEF,">>$ugenefile")
    or die "QAJobs::classifyCDS: Couldn't open unique genes file $ugenefile to write\n";
  # Now process the hits
  print "QAJobs::classifyCDS: Identifying long and short genes\n";
  my $seqhash={}; my $filtPBRhash={};
  BioUtils::putIntoHash($partf,1,8,$seqhash,"\t",1,'');
  BioUtils::getPBRs($genelist,$filtPBRfile,$filtPBRhash,1);
  print "Number of filtered reports=" . keys( %{ $filtPBRhash }) . "\n";
  foreach my $gene (sort keys %{ $filtPBRhash }) {
    if ($gene eq '') { print "Empty gene!!\n"; next; }
    #print "Examining gene=$gene\n";
    my $numeukhits=0; my $numweakhits=0; my $numgt30identity=0;
    my $completegenomes=0; my $warning=0;
    my $darr=(); my $qsmss=(); my $ssmqs=();
    my $selfbs=BioUtils::bl2seg($seqhash->{$gene},$pathp);
    my @reparr=split(/\n/,$filtPBRhash->{$gene});
    my $numhits=@reparr-1;
    $warning=1 if ($reparr[0]=~/WARNING/);
    for (my $i=1; $i<@reparr; $i++) { #Each subj
      next if ($reparr[$i]=~/^\s*$/);
      my @arr=split(/\t/,$reparr[$i]);
      $numeukhits++ if ($arr[15]==1);
      my $qb=$arr[3]; my $sb=$arr[5]; my $pi=$arr[8]; my $bs=$arr[7];
      push @$qsmss, $qb-$sb; push @$ssmqs, $sb-$qb;
      if ($bs<0.2*$selfbs && abs($qb-$sb)<30) { $numweakhits++; }; # Weak hits
      $numgt30identity++ if ($pi>30);
      if (!($arr[0]=~/^(ZP|XP)/) && abs($qb-$sb)<=10) { $completegenomes++; } # NM suggested this
      # D-score related computations
      my $d=($qb-$sb)/($qb+$sb); push @$darr,$d;
    }
    if ((!($iseuk) && $numhits==$numweakhits && ($numweakhits==$numeukhits)) || ($iseuk && $numhits==$numweakhits)) {
      print "QAJobs::classifyCDS: Found unique gene $gene\n";
      print UGENEF "$gene\n";
      next;
    }
    my @sorted=sort {$a <=> $b} @$darr;
    my $meand=BioUtils::arrAverage(\@sorted); my $mediand=BioUtils::arrMedian(\@sorted);
    my $diff=abs($meand-$mediand); #print "Mean=$meand, Median=$mediand, Diff=$diff\n";
    my $numfullyaln=QAUtils::getNumFullAlnHits($filtPBRhash->{$gene});
    my @sortedqms=sort {$a <=> $b} @$qsmss; my @sortedsmq=sort {$a <=> $b} @$ssmqs;
    #print "Gene=$gene, MeanD=$meand, MedianD=$mediand, Numfullyaln=$numfullyaln\n";
    if ($meand<=-0.5 && $diff<=0.3) { # Short gene candidate
      if ($numfullyaln<3) {
        while (1) {
	  if ($sortedsmq[0]<0) { splice(@sortedsmq,0,1); }
	  else { last; }
	}
	if (abs($mediand)>=0.7) { # Certain
	  print LSCDSF "$gene\tSHORT\t$sortedsmq[0]\t$sortedsmq[@sortedsmq-1]\t$warning\t$completegenomes\t$meand\t$mediand\n";
	} else { # Undecided
	  print UDF "$gene\tSHORT\t$sortedsmq[0]\t$sortedsmq[@sortedsmq-1]\t$warning\t$completegenomes\t$meand\t$mediand\n";
	}
      }
    } elsif ($meand>=0.5 && $diff<=0.3) { # Long gene candidate
      if ($numfullyaln<2) {
        while (1) {
	  if ($sortedqms[0]<0) { splice(@sortedqms,0,1); }
	  else { last; }
	}
	if (abs($mediand)>=0.7) { # Certain
	  print LSCDSF "$gene\tLONG\t$sortedqms[0]\t$sortedqms[@sortedqms-1]\t$warning\t$completegenomes\t$meand\t$mediand\n";
	} else { # Undecided
	  print UDF "$gene\tLONG\t$sortedqms[0]\t$sortedqms[@sortedqms-1]\t$warning\t$completegenomes\t$meand\t$mediand\n";
	}
      }
    } else {
      #print LSCDSF "$gene\tNORMAL\t$sortedqms[0]\t$sortedqms[@sortedqms-1]\t$warning\t$completegenomes\t$meand\t$mediand\n";
    }
  }
  close(INFILE); close(LSCDSF); close(DGENEF); close(UDF); close(UGENEF);
  return;
}

###############################################################################
# decideLongShort:
# 		Subroutine to examine the list of candidate (undecided)
# 		long/short genes and intergenic region blast hits
# 		and designate actual long/short hits from this list
# Arguments:	ARG1: File containing candidate long/short genes
# 		ARG2: File containing parsed artemis file
# 		ARG3: File with intergenic regions
# 		ARG4: File containing parsed intergenic blast hits
#		ARG5: File containing confidently predicted long/short genes
#		ARG6: File containing filtered blast hits for all genes
# Output:	File containing putative broken genes
# Author: Amrita Pati, Email: apati@lbl.gov
# Last Updated: 06/17/2008
###############################################################################
sub decideLongShort ($$$$$$) {
  
  my $candfile=$_[0]; my $partfile=$_[1]; my $intfile=$_[2];
  my $intblastfile=$_[3]; my $lshitsfile=$_[4]; my $allhitsfile=$_[5];

  my $starts={}; my $ends={}; my $signs={};

  # Store ORF begins and ends and signs
  open (PARTF,$partfile)
   or die "QAJobs::decideLongShort: Couldn't open $partfile to read\n";
  while (<PARTF>) {
    chomp($_); my $line=$_; my @arr=split(/\t/,$line);
    $arr[0]=~s/\s//g;
    $starts->{$arr[0]}=$arr[3]; $ends->{$arr[0]}=$arr[4];
    $signs->{$arr[0]}=$arr[2];
  }
  close (PARTF);

  # Store blast hits for all genes
  my $hithash={}; my $id='';
  open (HITF,$allhitsfile)
   or die "QAJobs::decideLongShort: Couldn't open $allhitsfile to read\n";
  while (<HITF>) {
    chomp($_); my $line=$_;
    if ($line=~/Report details: Query=(.+)\s\(.+\)\s,\sLength=(\d+),\sDatabase=.+/) {
      $id=$1; $hithash->{$id}=();
    } else {
      my @arr=split(/\t/,$line); $hithash->{$id}.="\t".$arr[0];
    }
  }
  close(HITF);

  # Store blast hits for all intergenic regions
  my $inthithash={}; $id='';
  open (HITF,$intblastfile)
   or die "QAJobs::decideLongShort: Couldn't open $intblastfile to read\n";
  while (<HITF>) {
    chomp($_); my $line=$_;
    if ($line=~/Report details: Query=(.+)\s(\(INT\d+\)\s)?\(.+\)\s,\sLength=(\d+),\sDatabase=.+/) {
      $id=$1;
      print "QAJobs::decideLongShort:ID=$id\n";
      $inthithash->{$id}=();
    } else {
      my @arr=split(/\t/,$line); $inthithash->{$id}.="\t".$arr[0];
    }
  }
  close(HITF);

  # Make hash list of all candidate Long/Short genes
  my $candhash={};
  open (CANDF,$candfile)
   or die "QAJobs::decideLongShort: Couldn't open $candfile to read\n";
  while (<CANDF>) {
    chomp($_); my $line=$_; my @arr=split(/\t/,$line);
    #my $gene=shift(@arr); shift(@arr);
    my $gene=shift(@arr);
    $candhash->{$gene}=join("\t",@arr);
  }
  close(CANDF);

  # Now scan intergenic regions to see if there are candidate long/short
  # genes on either side
  open (INTF,$intfile)
   or die "QAJobs::decideLongShort: Couldn't open $intfile to read\n";
  open (OUTF,">>$lshitsfile")
   or die "QAJobs::decideLongShort: Couldn't open $lshitsfile to read\n";
  while (<INTF>) {
    chomp($_); my $line=$_; my @arr=split(/\t/,$line);
    $arr[1]=~/(.+)-(.+)/; my $pid=$1; my $nid=$2;
    next if (!exists $signs->{$pid});
    if (exists $candhash->{$pid} && $signs->{$pid} eq '-' && QAUtils::isShortGene($pid,$candhash,$inthithash,$hithash,$arr[1])) {
      print OUTF "$pid\tSHORT gene with BLASTx hit\t$candhash->{$pid}\n";
      delete ($candhash->{$pid});
    } 
    if (exists $candhash->{$nid} && $signs->{$nid} eq '+' && QAUtils::isShortGene($pid,$candhash,$inthithash,$hithash,$arr[1])) {
      print OUTF "$nid\tSHORT gene with BLASTx hit\t$candhash->{$nid}\n";
      delete ($candhash->{$pid});
    } 
  }

  # Now scan the list of candidate long/short gene to see if there are any
  # long genes
  while ( my($key,$value)=each %{ $candhash } ) {
    next if (!($value=~/LONG/));
    if (QAUtils::isLongGene($key,$starts,$ends,$signs,$partfile)) {
      print OUTF "$key\tLONG gene with <100 nt promoter\t$candhash->{$key}\n";
      delete ($candhash->{$key});
    } 
  }
  close(INTF); close(OUTF);

  # Print remaining undecided back
  open (CANDF,">$candfile")
   or die "QAJobs::decideLongShort: Couldn't open $candfile to write\n";
  foreach my $gene (sort keys %{ $candhash }) {
    print CANDF "$gene\t$candhash->{$gene}\n";
  }
  close(CANDF);
}


###############################################################################
# classifyDub:
# 		Subroutine to classify a dubious gene based on its neighborhood
# 		The following classes are used:
# 		A. -------------> --> ----------> || <--------- <-- <----------
# 		B. -------------> <-- ---------> || <-------- ---> <---------
# 		C. ------------> <--> <----------
#		D. <------------ <--> ----------->
# Arguments:	ARG1: File containing parsed Artemis data
#		ARG2: CDS ID of the dubious gene being classified
# Author: Amrita Pati, Email: apati@lbl.gov
# Last Updated: 06/05/2008
###############################################################################
sub classifyDub ($$) {

  my $partf=$_[0]; my $geneid=$_[1];
  open(AFILE,$partf)
    or die "QAJobs::classifyDub: Couldn't open parsed artemis file $_[0]\n";

  print "QAJobs::classifyDub: Classifying dubious gene\n";
  my $LNbors={}; my $RNbors={};
  BioUtils::getNborFeats($partf,$LNbors,$RNbors);
  my $idlt=$LNbors->{$geneid}; my $idgt=$RNbors->{$geneid};
  my $ltflag=0; my $gtflag=0; my $idflag=0;

  my $idstr=''; my $gtstr=''; my $ltstr='';
  my $ids=0; my $ide=0; my $gts=0; my $gte=0; my $lts=0; my $lte=0;

  while (<AFILE>) {
    chomp($_); my @arr=split(/\t/,$_);
    if ($arr[0] eq $idlt) {
      $ltstr=$arr[2]; $lts=$arr[3]; $lte=$arr[4];
      $ltflag=1;
    } elsif ($arr[0] eq $idgt) {
      $gtstr=$arr[2]; $gts=$arr[3]; $gte=$arr[4];
      $gtflag=1;
    } elsif ($arr[0] eq $geneid) {
      $idstr=$arr[2]; $ids=$arr[3]; $ide=$arr[4];
      $idflag=1;
    }
    last if ($ltflag && $gtflag && $idflag);
  }
  close(AFILE);

  my $d1=$ids-$lte;
  my $d2=$gts-$ide;
  my $classtr=$ltstr.$idlt."[".$d1."]".$idstr.$geneid."[".$d2."]".$gtstr.$idgt;

  if (($ltstr eq $idstr)&&($idstr eq $gtstr)&&($gtstr eq $ltstr)) {
    $classtr="A"." (".$classtr.")";
  } elsif (($ltstr ne $idstr)&&($idstr ne $gtstr)&&($gtstr eq $ltstr)) {
    $classtr="B"." (".$classtr.")";
  } elsif (($gtstr eq '-')&&($ltstr eq '+')) {
    $classtr="C"." (".$classtr.")";
  } elsif (($gtstr eq '+')&&($ltstr eq '-')) {
    $classtr="D"." (".$classtr.")";
  }

  return($classtr);
  
}

###############################################################################
# findBrokenGenes:
# 		Subroutine to find pairs of predicted genes that might be
# 		pieces of the same gene
# Arguments:	ARG1: File containing parsed artemis file
# 		ARG2: File containing parsed blast hits from both blast runs
#		ARG3: Full Sequence
#		ARG4: Ouput file for putative broken genes
#		ARG5: Output file for blast ouput alignment
#		ARG6: Self draft
#		ARG7: Short/Long genes file
#		ARG8: Undecided genes file
#		ARG9: Ambiguous alignments file
# Output:	File containing putative broken genes
# Author: Amrita Pati, Email: apati@lbl.gov
# Last Updated: 06/17/2008
###############################################################################
sub findBrokenGenes {

  my ($partf,$pbrfile,$intpbrfile,$sequence,$bgfile,$bgalnfile,$selfdraft,$lsf,$ulsf,$aaf)=@_;

  $sequence=uc($sequence);

  system("touch $bgfile $bgalnfile");

  #print "findBrokenGenes: In here\n";
 
  my $shortgenes={}; my $signhash={}; my $starts={}; my $ends={}; my $protseqs={};
  my $LNbors={}; my $RNbors={}; my $aapbrs={}; my @garr; my $allpbrs={}; my $intpbrs={};
  my $ints={}; my $fusionstathash={}; my $sublendischash={}; my $commhithashrefs={};

  BioUtils::getNborFeats($partf,$LNbors,$RNbors);
  BioUtils::putIntoHash($lsf,1,-1,$shortgenes,"\t",1,'',"2:SHORT");
  BioUtils::putIntoHash($ulsf,1,-1,$shortgenes,"\t",1,'',"2:SHORT");
  BioUtils::putIntoHash($partf,1,8,$protseqs,"\t",1,'');
  BioUtils::putIntoHash($partf,1,3,$signhash,"\t",1,'');
  BioUtils::putIntoHash($partf,1,4,$starts,"\t",1,'');
  BioUtils::putIntoHash($partf,1,5,$ends,"\t",1,'');
  BioUtils::getPBRs($shortgenes,$aaf,$aapbrs,1);
  BioUtils::getPBRs($shortgenes,$pbrfile,$allpbrs,1);
  BioUtils::getPBRs($ints,$intpbrfile,$intpbrs,1);
  foreach my $key (sort { $starts->{$a} <=> $starts->{$b} } keys %{ $starts }) {
    push @garr, $key;
  }

  my $pid=''; my $ppid=''; my $preport=''; my $ppreport='';
  my $bghash={}; my $pairbrs={}; my $bgs={};
  foreach my $gene (@garr) {
    $ppid=$pid; $pid=$gene;
    #next if ($pid ne 'Natgr_00011670' && $ppid ne 'Natgr_00011670' && $pid ne 'Natgr_00011670' && $ppid ne 'Natgr_00011670');
    $preport=$allpbrs->{$pid};
    if ($ppid ne '') {
      $ppreport=$allpbrs->{$ppid};
      if ($signhash->{$pid} eq $signhash->{$ppid}) {
        my $seq='';
	if ($signhash->{$pid} eq '+') {
	  $seq=substr($sequence,$starts->{$ppid}-1,$ends->{$pid}-$starts->{$ppid}+1);
	} elsif ($signhash->{$pid} eq '-') {
	  $seq=Parser::revComp(substr($sequence,$starts->{$ppid}-1,$ends->{$pid}-$starts->{$ppid}+1));
	}
	# Make sure that the sequence doesn't contain a gap between contigs
	if ($seq=~/N{100,}/) { next; }
	my $isPair=0;
	if (exists $shortgenes->{$pid} || exists $shortgenes->{$ppid} || exists $aapbrs->{$pid} || exists $aapbrs->{$ppid}) {
	  my ($ans,$fusionflag,$sublendiscflag,$chhash)=QAUtils::areSameGene($ppid,$pid,$ppreport,$preport,$seq,$bgalnfile,"$selfdraft",$protseqs->{$ppid},$protseqs->{$pid},$starts->{$ppid},$starts->{$pid});
	  if ($ans ne '0') {
	    $isPair=1;
	    $pairbrs->{"$ppid$pid"}=$ans;
	    if ($fusionflag) {
	      $fusionstathash->{"$pid$ppid"}=1; $fusionstathash->{"$ppid$pid"}=1;
	    }
	    if ($sublendiscflag) {
	      $sublendischash->{"$pid$ppid"}=1; $sublendischash->{"$ppid$pid"}=1;
	    }
	    $commhithashrefs->{"$ppid$pid"}=$chhash;
	  }
	}
	my ($commcntpp,$commcntp)=(0,0);
	if (!$isPair) { # Check if it shares hits with neighboring broken gene set
	  if (exists $bgs->{$ppid}) {
	    my @barr=split(' ',$bgs->{$ppid});
	    foreach my $g (@barr) {
	      my $commhits=BioUtils::getCommonHits($allpbrs->{$pid},$allpbrs->{$g},0);
	      my $numcomm=keys %{ $commhits };
	      $commcntpp++ if ($numcomm>0);
	    }
	  } elsif (exists $bgs->{$pid}) {
	    my @barr=split(' ',$bgs->{$pid});
	    foreach my $g (@barr) {
	      my $commhits=BioUtils::getCommonHits($allpbrs->{$ppid},$allpbrs->{$g},0);
	      my $numcomm=keys %{ $commhits };
	      $commcntp++ if ($numcomm>0);
	    }
	  }
	  $isPair=1 if ($commcntpp>1 || $commcntp>1);
	}
	my $ig="$ppid-$pid";
	if (!$isPair && exists $intpbrs->{$ig}) { # Check if it shares hits with neighboring intergenic regions
	  my $ipbr=$intpbrs->{$ig};
	  if ($commcntpp>0) {
	    my $commhits=BioUtils::getCommonHits($allpbrs->{$pid},$ipbr,0);
	    my $numcomm=keys %{ $commhits };
	    $isPair=1 if ($numcomm>0);
	  } elsif ($commcntp>0) {
	    my $commhits=BioUtils::getCommonHits($allpbrs->{$ppid},$ipbr,0);
	    my $numcomm=keys %{ $commhits };
	    $isPair=1 if ($numcomm>0);
	  }
	}
	if ($isPair) {
	  $bghash->{$ppid}=$pid;
	  $bgs->{$ppid}=(exists $bgs->{$ppid})?"$bgs->{$ppid} $pid":"$ppid $pid";
	  $bgs->{$pid}=(exists $bgs->{$pid})?"$bgs->{$pid} $ppid":"$ppid $pid";
	  print "Putative broken gene:$ppid and $pid\n";
	}
      }
    }
  }

  # COnsolidate broken gene pairs into broken gene sets with possibly >2 genes
  # when applicable
  my $donehash={};
  my $numshorts = keys %{ $shortgenes }; my $numbgs = keys %{ $bghash };
  print "Number of short genes = $numshorts\nNumber of broken gene sets = $numbgs\n";
  open (BF,">>$bgfile")
    or die "QAJobs::findBrokenGenes: Couldn't open output file $bgfile to write\n";
  foreach my $gene (sort keys %{ $bghash }) {
    next if (exists $donehash->{$gene});
    $donehash->{$gene}=1; my $isshort=0;
    if (exists $shortgenes->{$gene} || exists $aapbrs->{$gene}) { $isshort=1; }
    my @thisarr;
    push @thisarr, $gene;
    while (exists $bghash->{$gene}) {
      $gene=$bghash->{$gene};
      if (exists $shortgenes->{$gene} || exists $aapbrs->{$gene}) { $isshort=1; }
      push @thisarr, $gene;
      $donehash->{$gene}=1;
    }
    # Check that the order of alignment of genes on the common subject is the same
    my $numdiscords=0; my $discords={}; my $sanehits={}; my $chhash={};
    my ($ans,$fusionflag,$sublendiscflag);
    for (my $i=0; $i<@thisarr-1; $i++) {
      for (my $j=$i+1; $j<@thisarr; $j++) {
	my $ppid=$thisarr[$i]; my $pid=$thisarr[$j];
	next if (exists $pairbrs->{"$ppid$pid"});
	if ($ppid=~/-/) {
	  my $relor='IRGENE';
	  ($ans,$sanehits)=QAUtils::areSameGeneIR($pid,$ppid,$signhash->{$pid},$allpbrs->{$pid},$intpbrs->{$ppid},$relor);
	} elsif ($pid=~/-/) {
	  my $relor='GENEIR';
	  ($ans,$sanehits)=QAUtils::areSameGeneIR($ppid,$pid,$signhash->{$ppid},$allpbrs->{$ppid},$intpbrs->{$pid},$relor);
	} else {
          my $seq='';
	  if ($signhash->{$pid} eq '+') {
	    $seq=substr($sequence,$starts->{$ppid}-1,$ends->{$pid}-$starts->{$ppid}+1);
	  } elsif ($signhash->{$pid} eq '-') {
	    $seq=Parser::revComp(substr($sequence,$starts->{$ppid}-1,$ends->{$pid}-$starts->{$ppid}+1));
	  }
	  ($ans,$fusionflag,$sublendiscflag,$chhash)=QAUtils::areSameGene($ppid,$pid,$allpbrs->{$ppid},$allpbrs->{$pid},$seq,$bgalnfile,$selfdraft,$protseqs->{$ppid},$protseqs->{$pid},$starts->{$ppid},$starts->{$pid});
	}
	if ($ans eq '0') {
	  $numdiscords++; $discords->{"$ppid,$pid"}=1;
	  if ($fusionflag) {
	    $fusionstathash->{"$pid$ppid"}=1; $fusionstathash->{"$ppid$pid"}=1;
	  }
	  if ($sublendiscflag) {
	    $sublendischash->{"$pid$ppid"}=1; $sublendischash->{"$ppid$pid"}=1;
	  }
	}
      }
    }
    #print "FindBroken: Original set=",join(' ',@thisarr),"\n";
    #print "FindBroken: Discordant sets=",join(' ',keys %{ $discords }),"\n";
    #print "FindBroken: Fusion stat hash keys=",join(' ',keys %{ $fusionstathash }),"\n";
    #print "FindBroken: Sublen disc hash keys=",join(' ',keys %{ $sublendischash }),"\n";
    if (scalar(keys %{ $discords})==0) {
      if (@thisarr==2 && (exists $fusionstathash->{"$thisarr[0]$thisarr[1]"} or exists $fusionstathash->{"$thisarr[1]$thisarr[0]"} or exists $sublendischash->{"$thisarr[0]$thisarr[1]"} or exists $sublendischash->{"$thisarr[1]$thisarr[0]"})) {
	print join(' ',@thisarr), " is a possible fusion gene or has subj len discrepancies\n";
      } else {
        if ($isshort) {
          print BF "Putative broken gene: ";
          print BF join(' ',@thisarr),"\n";
        }
        next;
      }
    }
    # Prune geneset based on discords
    my $newbgsets=QAUtils::pruneBGset(\@thisarr,$discords);
    if (scalar(keys %{ $newbgsets})==0) {
      # Send each individual gene for extension/tagging
      open (LSF,">>$lsf")
	or die "Couldn't open $lsf to append\n";
      foreach my $thisg (@thisarr) {
        print LSF "$thisg\tSHORT\t\t\t\t\t\t\n";
      }
      close (LSF);
    }

    foreach my $bgset (keys %{ $newbgsets }) {
      my @tarr=split(',',$bgset);
      #print "FindBroken: Tarr=",join(' ',@tarr),"\n";
      if (@tarr==1) {
        # Send each individual gene for extension/tagging
        open (LSF,">>$lsf")
	  or die "Coudln't open $lsf to append\n";
        foreach my $thisg (@thisarr) {
          print LSF "$thisg\tSHORT\t\t\t\t\t\t\n";
        }
        close (LSF);
      } elsif (@tarr==2 && (exists $fusionstathash->{"$tarr[0]$tarr[1]"} or exists $fusionstathash->{"$tarr[1]$tarr[0]"} or exists $sublendischash->{"$tarr[0]$tarr[1]"} or exists $sublendischash->{"$tarr[1]$tarr[0]"})) {
	print join(' ',@tarr), " is a possible fusion gene or has subj len discrepancies\n";
      } else {
        if ($isshort) {
          print BF "Putative broken gene: ";
          print BF join(' ',@tarr),"\n";
        }
      }
    } # End for

  }
  close(BF);
  return($bgs);
}

###############################################################################
# findInterruptedGenes:
# 		Subroutine to find genes interrupted by transposases by
# 		analyzing pairs of genes across the genome that have the
# 		same BLASTp hits
# Arguments:	ARG1: List of features
# 		ARG2: Feature strands
#		ARG3: List of long short genes
#		ARG4: List of candidate long/short genes
# 		ARG5: Filtered parsed blast results
#		ARG6: Output file for putative interrupted genes
# Output:	File containing putative interrupted genes
# Author: Amrita Pati, Email: apati@lbl.gov
# Last Updated: 06/19/2008
###############################################################################
sub findInterruptedGenes ($$$$$$$$$) {
  my ($featList,$featStrands,$lsFile,$lsUFile,$allhitsfile,$outFile,$featstarts,$featends,$brokengenes)=@_;

  system("touch $outFile");
  if (!$featList) { return; }

  my $prefixfile='';
  if ($lsFile=~/(.+)longshort\.txt/ || $lsFile=~/(.+)longshortGenes.txt/) {
    $prefixfile=$1."id.txt";
  }
  my $idprefix=QAUtils::getIDprefix($prefixfile);

  my $shortgenes={};

  # Read in (putative)short genes
  open (SF,$lsFile) or die "QAJobs::findInterruptedGenes: Couldn't open $lsFile\n";
  while (<SF>) {
    chomp($_); my @arr=split(/\t/,$_); $shortgenes->{$arr[0]}=1 if ($arr[1] eq 'SHORT');
  } close(SF);
  open (SF,$lsUFile) or die "QAJobs::findInterruptedGenes: Couldn't open $lsUFile\n";
  while (<SF>) {
    chomp($_); my @arr=split(/\t/,$_); $shortgenes->{$arr[0]}=1 if (!exists $shortgenes->{$arr[0]});
  } close(SF);

  # Read in BLASTp hits
  my $hithash={}; my $coords={}; my $id='';
  open (HITF,$allhitsfile) or die "QAJobs::findInterruptedGenes: Couldn't open $allhitsfile\n";
  while (<HITF>) {
    chomp($_); my $line=$_;
    next if ($line eq '');
    if ($line=~/Report details: Query=(.+)\s\(.+\)\s,\sLength=(\d+),\sDatabase=.+/) {
      $id=$1; $hithash->{$id}=''; $coords->{$id}='';
    } else { my @arr=split(/\t/,$line); 
      $hithash->{$id}.="\t".$arr[0]; $coords->{$id.$arr[0]}=join("\t",@arr);
    }
  }
  close(HITF);

  open (OUTF,">$outFile") or die "QAJobs::findInterruptedGenes: Couldn't open $outFile\n";
  #while (my($key,$value)=each %{ $shortgenes }) {
  for (my $j=0; $j<@{ $featList }; $j++) {
    my $printstr=''; my $numcands=0; my $feat1=$featList->[$j];
    next if (!(exists $shortgenes->{$feat1}) && !(exists $brokengenes->{$feat1}));
    for (my $i=0; $i<@{ $featList }; $i++) {
      next if (!($featList->[$i]=~/^$idprefix/));
      if (!defined $featStrands->{$featList->[$i]} || !defined $featStrands->{$feat1}) {
	print "No information for $featList->[$i] or $feat1**\n"; next;
      }
      next if ($featStrands->{$feat1} ne $featStrands->{$featList->[$i]});
      my $decision=QAUtils::isInterruptedGene($feat1,$featList->[$i],$hithash,$coords,$featStrands->{$feat1},$featstarts,$featends);
      if ($decision) {
        $printstr.="$feat1\tshared hits with gene ".$featList->[$i]."\n";
	print "$printstr";
	$numcands++;
      }
    }
    print "CANDS = $numcands\n";
    if ($numcands<=2) {
      print OUTF $printstr;
    }
  }
  close(OUTF);

}
1;
