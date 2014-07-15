package Parser;

# Author: Amrita Pati, Genome Biology JGI
# Email: apati@lbl.gov

use strict;
use Carp;
use GeneticCode;
use Param;
use BioUtils;
use Bio::SeqIO;
use Bio::Tools::GFF;
use BPlite;

###############################################################################
# parseTextFile: Subroutine to extract gene features from a tab-delimited text file
# Arguments: Have to be all of the following in any order
# 		startfield=columnnumber
#		endfield=columnnumber
#		strandfield=columnnumber
#		featuretype=columnnumber, -1 if it doesn't exist
#		locus=0 or >0, says whether locus tags have been assigned
###############################################################################
sub parseTextFile {

  open(INFILE,$_[0]);
  open(OUTFILE,">$_[1]")
    or die ("Couldn't open output file $_[1] for writing\n");
  
  my $featList=$_[2]; my $featType=$_[3]; my $featStrand=$_[4];
  my $featStart=$_[5]; my $featEnd=$_[6]; my $featNote=$_[7];
  my $sequence=$_[8]; $featList->[0]=0; my $featCnt=0;

  my $idprefix=''; my $delim=''; my $startfnum=''; my $endfnum='';
  my $strandfnum=''; my $featfnum=''; my $islocus=0; my $idcnt=0;
  my $notefnum='';

  for (my $i=9; $i<@_; $i++) {
    my $param=$_[$i];
    if ($param=~/^startfield=(.+)/) { $startfnum=$1; next; }
    elsif ($param=~/^endfield=(.+)/) { $endfnum=$1; next; }
    elsif ($param=~/^strandfield=(.+)/) { $strandfnum=$1; next; }
    elsif ($param=~/^featuretype=(.+)/) { $featfnum=$1; next; }
    elsif ($param=~/^notefield=(.+)/) { $notefnum=$1; next; }
    elsif ($param=~/^locus=(.+)/) { $islocus=$1; next; }
  }

  if (!$startfnum || !$endfnum || !$strandfnum) {
    die "parseTextFile: Essential parser parameters missing\n";
  }

  if ($islocus==0) { $idprefix="or"; }

  while (<INFILE>) {
    chomp($_); my $line=$_; my @arr=split(/\t/,$line);
    my $thislocus='';
    if (!$islocus) {
      $idcnt++; $thislocus=$idprefix.$idcnt;
    } else {
      $thislocus=$arr[$islocus-1];
    }
    push @$featList, $thislocus;
    if ($featfnum) { $featType->{$thislocus}=$arr[$featfnum-1]; }
    else { $featType->{$thislocus}='CDS'; }
    $featStart->{$thislocus}=$arr[$startfnum-1];
    $featEnd->{$thislocus}=$arr[$endfnum-1];
    if ($featEnd->{$thislocus}<$featStart->{$thislocus}) {
      my $temp=$featStart->{$thislocus};
      $featStart->{$thislocus}=$featEnd->{$thislocus};
      $featEnd->{$thislocus}=$temp;
    }
    if ($arr[$strandfnum-1]=~/^-/) {
      $featStrand->{$thislocus}='-';
     } else {
      $featStrand->{$thislocus}='+';
    }
    if ($notefnum) { $featNote->{$thislocus}=$arr[$notefnum-1]; }
    else { $featNote->{$thislocus}=''; }
    $featCnt++;
  }

  $featCnt=keys %{ $featStart }; @$featList=(); my $featidx=1; $featList->[0]=0; my $seq='';
  print "Size=$featCnt\n";
  foreach my $feat (sort { $featStart->{$a} <=> $featStart->{$b} } (keys %{ $featStart })) {
    #print "Feature=$feat, Start=$featStart->{$feat}, End=$featEnd->{$feat}, Strand=$featStrand->{$feat}\n";
    if($featStrand->{$feat} eq '+') {
      $seq=substr($sequence,$featStart->{$feat}-1,$featEnd->{$feat}-$featStart->{$feat}+1);
    } else {
      $seq=revComp(substr($sequence,$featStart->{$feat}-1,$featEnd->{$feat}-$featStart->{$feat}+1));
    }
    my $protseq='';
    $featList->[$featidx]=$feat; $featidx++;
    for (my $idx=0; $idx<=length($seq)-3; $idx=$idx+3) {
      $protseq=$protseq.GeneticCode::genCode(uc(substr($seq,$idx,3)));
    }
    print OUTFILE "$feat\t$featType->{$feat}\t$featStrand->{$feat}\t$featStart->{$feat}\t$featEnd->{$feat}\t$featNote->{$feat}\t$seq\t$protseq\n";
  }
  close(INFILE); close(OUTFILE);
}

###############################################################################
# revComp:	Compute the reverse complement of a given DNA sequence
# Arguments:	ARG1: DNA sequence
# Returns:	Reverse complement
# Author: Amrita Pati, Email: apati@lbl.gov
# Date: 05/27/2008
###############################################################################

sub revComp {
  my $seq = $_[0];
  my %revhash = (
  	A => 'T',
     	T => 'A',
     	C => 'G',
	G => 'C',
	N => 'N',
  	a => 't',
     	t => 'a',
     	c => 'g',
	g => 'c',
	n => 'n',
  );
  my $compSeq = '';
  for (my $i=length($seq)-1; $i>=0; $i--) {
    $compSeq=$compSeq.$revhash{substr($seq,$i,1)};
  }
  return($compSeq);
}

# Convert a combination of GFF3 and Fasta files into Genbank
sub convertGff3Fna2Gb {
  my ($gff3file,$fnafile,$gbfile)=@_;
  my $gffio=Bio::Tools::GFF->new(-file => $gff3file, -gff_version => 3);
  my $fnaio=Bio::SeqIO->new(-file => $fnafile, -format => 'Fasta');
  my $gbio=Bio::SeqIO->new(-file => ">$gbfile", -format => 'genbank');
  
  my $feathash={};
  while (my $feature = $gffio->next_feature()) {
    my $featseqid=$feature->seq_id();
    if (!exists $feathash->{$featseqid}) {
      $feathash->{$featseqid}=();
    }
    push @{ $feathash->{$featseqid} }, $feature;
  }
  

  # Get sequence object first
  my $numseqs=0;
  while ( my $seqobj=$fnaio->next_seq() ) {
    $numseqs++;
    if ($numseqs>1) {
      print "Parser::convertGff3Fna2Gb: More than one sequence in Fasta file.\nSomething wrong. Quitting.\n";
      exit;
    }
    my $seqid=$seqobj->id();
    $seqobj->accession_number($seqid);
    # Now attach features to the sequence object
    foreach my $feat (@{ $feathash->{$seqid} }) {
      $seqobj->add_SeqFeature($feat);
    }
    # Now, write to output
    $gbio->write_seq($seqobj);
  }
}


# BioPerl based GFF3 parser
# Assuming that multiple seqs may be present in the file
sub parseGFF3 {

  my ($gfffile,$outf,$featList,$featType,$featStrand,$featStart,$featEnd,$featNote,$tool,$ifiletype)=@_;
  my $callcrisprs='Y'; my $crisprcnt=0; my $nextnewfeat=1;
  if ($_[10]) { $callcrisprs=$_[10]; }
  $outf=~/(.+)_(.+)/; my $pathp=$1; my $idf=$pathp."_id.txt";
  
  $featList->[0]=0; my $featcnt=1; my $featDNA={}; my $featProt={};

  my $gffio=Bio::Tools::GFF->new(-file => $gfffile, -gff_version => 3);
  
  while (my $feat = $gffio->next_feature()) {
      my $feattype=$feat->primary_tag;
      next if ($feattype=~/gene|sig_peptide|mobile_element|mat_peptide/i);
      if ($callcrisprs eq 'N' && $feattype eq 'repeat_region') {
	$crisprcnt++; my $featid="orf_CrispR$crisprcnt";
	$featType->{$featid}='CRISPR';
	$featStrand->{$featid}=$feat->strand();
	$featStart->{$featid}=$feat->start;
	$featEnd->{$featid}=$feat->end;
	$featNote->{$featid}=''; $featDNA->{$featid}=''; $featProt->{$featid}='';
	next;
      } elsif ($callcrisprs eq 'Y' && $feattype eq 'repeat_region') {
	next;
      }
      if ($callcrisprs eq 'N' && ($feattype eq 'misc_feature' || $feattype eq 'misc_binding')) {
	
      } elsif ($callcrisprs eq 'Y' && ($feattype eq 'misc_feature' || $feattype eq 'misc_binding')) {
	next;
      }
      my $featid='';
      if (exists $feat->{'_gsf_tag_hash'}->{'locus_tag'}) {
        my @featidarr=$feat->get_tag_values('locus_tag');
        $featid=join('',@featidarr);
      } elsif (exists $feat->{'_gsf_tag_hash'}->{'gene'}) {
        my @featidarr=$feat->get_tag_values('gene');
        $featid=join('',@featidarr);
      } else {
	print "Locus tag does not exist for this feature of type $feattype\n";
      }
      if ($featid eq '') { $featid='Newfeat'.$nextnewfeat; $nextnewfeat++; }
      my $start=$feat->start; my $end=$feat->end;
      my $strand=$feat->strand();
      #print "Feature Locus Tag=$featid, Start=$start, End=$end, Strand=$strand\n";
      my $fullseq=$feat->entire_seq();
      my $dnaseq=''; my $findnaseq='';
      $findnaseq=substr($fullseq->seq(),$start-1,$end-$start+1) if ($strand==1);
      $findnaseq=revComp(substr($fullseq->seq(),$start-1,$end-$start+1)) if ($strand==-1);
      
      #print "Final DNA seq = $findnaseq\n";
      my $protseq='';
      if (exists $feat->{'_gsf_tag_hash'}->{'translation'}) {
        my @protarr=$feat->get_tag_values('translation');
	$protseq=join('',@protarr);
      } else {
	#print "Translation does not exist for this feature of type $feattype and featid $featid\n";
	if ($findnaseq ne '') {
	  $protseq=BioUtils::translateDNA2Protein($findnaseq);
	}
      }

      $featList->[$featcnt]=$featid; $featType->{$featid}=$feattype;
      if ($strand==1) { $featStrand->{$featid}='+'; }
      elsif ($strand==-1) { $featStrand->{$featid}='-'; }
      $featStart->{$featid}=$start; $featEnd->{$featid}=$end;
      if (exists $feat->{'_gsf_tag_hash'}->{'product'}) {
        $featNote->{$featid}=join('',$feat->get_tag_values('product')).", Tools=$tool";
      } else {
	#print "Product does not exist for this feature of type $feattype and featid $featid\n";
      }
      $featDNA->{$featid}=$findnaseq; $featProt->{$featid}=$protseq;
      $featcnt++;
  }

  open(OF,">$outf")
    or die "Couldn't open $outf to write\n";
  $featcnt=@{ $featList }; @$featList=(); my $featidx=1; $featList->[0]=0;
  print "Size=$featcnt\n";
  foreach my $feat (sort { $featStart->{$a} <=> $featStart->{$b} } (keys %{ $featStart })) {
    $featList->[$featidx]=$feat; $featidx++;
    print OF "$feat\t$featType->{$feat}\t$featStrand->{$feat}\t$featStart->{$feat}\t$featEnd->{$feat}\t$featNote->{$feat}\t$featDNA->{$feat}\t$featProt->{$feat}\n";
  }
  close(OF);
  return($nextnewfeat);
}

# BioPerl based Genbank/EMBL parser
sub parseGBorEMBLfile {

  my $gbfile=$_[0]; my $outf=$_[1];
  my $featList=$_[2]; my $featType=$_[3]; my $featStrand=$_[4];
  my $featStart=$_[5]; my $featEnd=$_[6]; my $featNote=$_[7];
  my $tool=$_[8]; my $nextnewfeat=1;
  my $ifiletype=$_[9];
  my $callcrisprs='Y'; my $crisprcnt=0;
  if ($_[10]) { $callcrisprs=$_[10]; }
  $outf=~/(.+)_(.+)/; my $pathp=$1; my $idf=$pathp."_id.txt";
  
  $featList->[0]=0; my $featcnt=1; my $featDNA={}; my $featProt={};

  my $in=Bio::SeqIO->new(-file => $gbfile, '-format' => $ifiletype);

  while (my $seq = $in->next_seq()) {

    foreach my $feat ($seq->get_SeqFeatures()) {
      my $feattype=$feat->primary_tag;
      next if ($feattype=~/gene|source|sig_peptide|mobile_element|mat_peptide|fasta_record|protein/i);
      if ($callcrisprs eq 'N' && $feattype eq 'repeat_region') {
	$crisprcnt++; my $featid="orf_CrispR$crisprcnt";
	$featType->{$featid}='CRISPR';
	$featStrand->{$featid}=$feat->strand();
	$featStart->{$featid}=$feat->start;
	$featEnd->{$featid}=$feat->end;
	$featNote->{$featid}=''; $featDNA->{$featid}=''; $featProt->{$featid}='';
	next;
      } elsif ($callcrisprs eq 'Y' && $feattype eq 'repeat_region') {
	next;
      }
      if ($callcrisprs eq 'N' && ($feattype eq 'misc_feature' || $feattype eq 'misc_binding')) {
	
      } elsif ($callcrisprs eq 'Y' && ($feattype eq 'misc_feature' || $feattype eq 'misc_binding')) {
	next;
      }
      my $featid='';
      if (exists $feat->{'_gsf_tag_hash'}->{'locus_tag'}) {
        my @featidarr=$feat->get_tag_values('locus_tag');
        $featid=join('',@featidarr);
      } elsif (exists $feat->{'_gsf_tag_hash'}->{'gene'}) {
        my @featidarr=$feat->get_tag_values('gene');
        $featid=join('',@featidarr);
      } else {
	print "Locus tag does not exist for this feature of type $feattype\n";
      }
      if ($featid eq '') { $featid='Newfeat'.$nextnewfeat; $nextnewfeat++; }
      my $start=$feat->start; my $end=$feat->end;
      my $strand=$feat->strand();
      #print "Feature Locus Tag=$featid, Start=$start, End=$end, Strand=$strand\n";
      my $fullseq=$feat->entire_seq();
      my $dnaseq=''; my $findnaseq='';
      $findnaseq=substr($fullseq->seq(),$start-1,$end-$start+1) if ($strand==1);
      $findnaseq=revComp(substr($fullseq->seq(),$start-1,$end-$start+1)) if ($strand==-1);
      
      #print "Final DNA seq = $findnaseq\n";
      my $protseq='';
      if (exists $feat->{'_gsf_tag_hash'}->{'translation'}) {
        my @protarr=$feat->get_tag_values('translation');
	$protseq=join('',@protarr);
      } else {
	#print "Translation does not exist for this feature of type $feattype and featid $featid\n";
	if ($findnaseq ne '') {
    	  for (my $idx=0; $idx<=length($findnaseq)-3; $idx=$idx+3) {
      	    $protseq=$protseq.GeneticCode::genCode(uc(substr($findnaseq,$idx,3)));
    	  }
	}
      }
      $protseq=~s/\s+//g;

      $featList->[$featcnt]=$featid; $featType->{$featid}=$feattype;
      if ($strand==1) { $featStrand->{$featid}='+'; }
      elsif ($strand==-1) { $featStrand->{$featid}='-'; }
      $featStart->{$featid}=$start; $featEnd->{$featid}=$end;
      if (exists $feat->{'_gsf_tag_hash'}->{'product'}) {
        $featNote->{$featid}=join('',$feat->get_tag_values('product')).", Tools=$tool";
      } else {
	#print "Product does not exist for this feature of type $feattype and featid $featid\n";
      }
      $featDNA->{$featid}=$findnaseq; $featProt->{$featid}=$protseq;
      $featcnt++;
    }
  }

  open(OF,">$outf")
    or die "Couldn't open $outf to write\n";
  $featcnt=@{ $featList }; @$featList=(); my $featidx=1; $featList->[0]=0;
  foreach my $feat (sort { $featStart->{$a} <=> $featStart->{$b} } (keys %{ $featStart })) {
    $featList->[$featidx]=$feat; $featidx++;
    if (not exists $featProt->{$feat}) { $featProt->{$feat}=''; }
    if (not exists $featDNA->{$feat}) { $featDNA->{$feat}=''; }
    if (not exists $featNote->{$feat}) { $featNote->{$feat}=''; }
    print OF "$feat\t$featType->{$feat}\t$featStrand->{$feat}\t$featStart->{$feat}\t$featEnd->{$feat}\t$featNote->{$feat}\t$featDNA->{$feat}\t$featProt->{$feat}\n";
  }
  close(OF);
  return($nextnewfeat);
}

# Get protein sequence for a given DNA sequence
sub translate {
  my ($dna,$strand)=@_; my $translation='';
  #print "DNA=$dna\n";
  my $findna='';
  if ($strand eq '+') { $findna=$dna; }
  elsif ($strand eq '-') { $findna=revComp($dna); }
  #print "Final DNA=$findna\n";
  for (my $idx=0; $idx<=length($dna)-3; $idx=$idx+3) {
    $translation=$translation.GeneticCode::genCode(uc(substr($findna,$idx,3)));
  }
  return($translation);
}

###############################################################################
# convertM0toM8:Subroutine to parse a multiple BLASTP output file
# 		and convert m0 format output to m8 format output
# Arguments:	ARG1: File containing blast results in m0 format
# 		ARG2: Output file for parsed results in m8 format
# Author: Amrita Pati, Email: apati@lbl.gov
# Last Updated: 08/03/2009
###############################################################################
sub convertM0toM8 {

  my $multireport=new BPlite::Multi("$_[0]");
  open (OUTF, ">$_[1]")
    or die "QAJobs::convertM0toM8: Couldn't open output file $_[1] for writing";

  print "QAJobs::convertM0toM8: Parsing BLAST output\n";

  # Get next blast report
  while (my $report=$multireport->nextReport) {

    my $query=$report->query;
    $query=~s/\(\d+ letters\)//g;
    my $querylen=$report->queryLength;
    my $database=$report->database;

    # Get next subject
    while(my $sbjct = $report->nextSbjct) {
      $sbjct->name=~ m/>([^\s]*)\s([^\n]*)/;
      my $sbjctID=$1;
      my $sbjctAnnotation=$2;
      $sbjctAnnotation=~s/\/([^\n]*)//; # Subject annotation
      my $sl=$sbjct->length; # Subject length
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
        my $qg=$hsp->queryGaps; # Gaps on query
        my $sg=$hsp->sbjctGaps; # Gaps on subject

	my $alnlenonsub=abs($se-$sb)+1;
	my $mismatches=$alnlenonsub-$match;

	# Print desired values in desired format
	
	print OUTF "$query\t$sbjctID\t";
	print OUTF "$percent\t$alnlenonsub\t";
	print OUTF "$mismatches\t$qg\t";
	print OUTF "$qb\t$qe\t$sb\t$se\t";
	print OUTF "$p\t$bits\n";
      }
    }
  }
  close(OUTF);
}

# Convert genbank/EMBL format file to GFF3
sub convert2GFF3 {

  my ($inputf,$outputf,$source)=@_;
  my $inputfileformat=BioUtils::getFileType($inputf);
  $inputfileformat=~s/GB/genbank/g;
  
  open (OUTF,">$outputf")
    or die "convert2GFF3: $outputf could not be opened for writing\n";
  print OUTF "##gff-version 3";
  my $in=Bio::SeqIO->new(-file => $inputf, '-format' => $inputfileformat);
  my $outputseqfile=$outputf."_seqs.faa";
  my  $outfaafh = Bio::SeqIO->new(-file => ">$outputseqfile" ,
                           -format => 'Fasta');

  while (my $seqobj = $in->next_seq()) {
    # Write fasta
    $outfaafh->write_seq($seqobj);

    # Extract sequence features
    my $s_accession=$seqobj->accession_number();
    my $s_disp_id=$seqobj->display_id();
    my $s_len=$seqobj->length();
    my $featStarts={}; my $featEnds={}; my $featChars={}; my $featExons={};
    my $crisprcnt=0; my $newfeatcnt=0;
    print OUTF "##sequence-region $s_disp_id 1 $s_len\n";

    foreach my $feat ($seqobj->get_SeqFeatures()) {
      my $feattype=$feat->primary_tag;
      #next if ($feattype=~/gene|sig_peptide|mobile_element|mat_peptide/i);
      next if ($feattype=~/misc_binding|misc_feature/);
      my $featid='';

      # First take care of repeat_regions, misc_binding, and misc_feature
      if ($feattype eq 'repeat_region') {
	$crisprcnt++; $featid="CrispR$crisprcnt";
      }
      if (exists $feat->{'_gsf_tag_hash'}->{'locus_tag'}) {
        my @featidarr=$feat->get_tag_values('locus_tag');
        $featid=join('',@featidarr);
      } elsif (exists $feat->{'_gsf_tag_hash'}->{'gene'}) {
        my @featidarr=$feat->get_tag_values('gene');
        $featid=join('',@featidarr);
      } else {
	print "Locus tag does not exist for this feature of type $feattype\n";
      }
      if ($featid eq '') { $newfeatcnt++; $featid='Newfeat'.$newfeatcnt; }
      # Capture partial gene related info
      my $isPartial=0; my $numFragments=0; my $partialStart=0; my $partialEnd=0;
      my $pstarttype=$feat->location->start_pos_type();
      my $pendtype=$feat->location->end_pos_type();
      if ($pstarttype=~/BEFORE|AFTER/ || $pendtype=~/BEFORE|AFTER/ || $feat->location->to_FTstring()=~/<|>/) {
	$isPartial=1;
      }
      $featChars->{$featid}->{"type"}=$feattype;
      $featChars->{$featid}->{"strand"}=$feat->strand()==1?'+':'-';
      $featChars->{$featid}->{"start"}=$feat->start;
      if ($pstarttype=~/BEFORE/ or $feat->location->to_FTstring()=~/</) {
	$featChars->{$featid}->{"start"}="<".$feat->start; $partialStart=1;
      }
      $featChars->{$featid}->{"end"}=$feat->end;
      if ($pendtype=~/AFTER/ or $feat->location->to_FTstring()=~/>/) {
	$featChars->{$featid}->{"end"}=">".$feat->end; $partialEnd=1;
      }
      my $start=$feat->start; my $end=$feat->end; my $strand=$feat->strand();
      $featStarts->{$featid}=$start; $featEnds->{$featid}=$end;
      print "Feature Locus Tag=$featid, Start=$start, End=$end, Strand=$strand\n";
      if ($feat->has_tag('pseudo')) {
	$featChars->{$featid}->{"pseudo"}="yes";
      } else {
	$featChars->{$featid}->{"pseudo"}="no";
      }

      my $protseq='';
      my $fullseq=$feat->entire_seq();
      if ($feat->has_tag('translation')) {
	$feat->remove_tag('translation');
      }
      if ($feat->location->isa('Bio::Location::SplitLocationI')) {
	my @sublocs=$feat->location->sub_Location();
      	foreach my $location ($feat->location->sub_Location) {
	  my ($thisstart,$thisend)=($location->start,$location->end);
	  my $thisexon=$featid.'_exon'.eval($numFragments+1);
	  $featExons->{$featid}->{$thisexon}->{"start"}=$thisstart;
	  $featExons->{$featid}->{$thisexon}->{"end"}=$thisend;
	  my $frame=1;
	  if ($strand==1) { $frame=($thisstart+2)%3; $frame=3 if ($frame==0); }
	  if ($strand==-1) { $frame=($s_len-$thisend)%3; $frame=3 if ($frame==0); } $frame='-'.$frame;
	  $featExons->{$featid}->{$thisexon}->{"frame"}=$frame;
	  if ($numFragments==0 and $strand==1 and ($pstarttype=~/BEFORE/ or $feat->location->to_FTstring()=~/</)) {
	    if ($partialStart) {
	      $featExons->{$featid}->{$thisexon}->{"start"}="<".$thisstart;
	    }
	    if ($feat->has_tag('codon_start')) {
	      my @csvals=$feat->get_tag_values('codon_start');
	      if (@csvals) {
	    	$featChars->{$featid}->{'codon_start'}=$csvals[0];
	    	$thisstart=$thisstart+$csvals[0]-1;
	      } else {
	       print "ERROR: $featid: CDS (start=$start, end=$end) seems to be a partial gene, but no codon_start has been specified. Translation might be incorrect!\n";
	       exit(1);
	      }
	    }
	  }
	  if ($numFragments==@sublocs-1 and $strand==-1 and ($pendtype=~/AFTER/ or $feat->location->to_FTstring()=~/>/)) {
	    if ($partialEnd) {
	      $featExons->{$featid}->{$thisexon}->{"end"}=">".$thisend;
	    }
	    if ($feat->has_tag('codon_start')) {
	      my @csvals=$feat->get_tag_values('codon_start');
	      if (@csvals) {
	    	$featChars->{$featid}->{'codon_start'}=$csvals[0];
	        $thisend=$thisend-$csvals[0]+1;
	      } else {
	       print "ERROR: $featid: CDS (start=$start, end=$end) seems to be a partial gene, but no codon_start has been specified. Translation might be incorrect!\n";
	       exit(1);
	      }
	    }
	  }
          $numFragments++;
	  my $thisfrag=$seqobj->subseq($thisstart,$thisend);
	  $featExons->{$featid}->{$thisexon}->{"translation"}=BioUtils::translateDNA2Protein($thisfrag);;
	  if ($strand==1) {
	    $protseq=$protseq.BioUtils::translateDNA2Protein($thisfrag);
	  } else {
	    $protseq=BioUtils::translateDNA2Protein(Parser::revComp($thisfrag)).$protseq;
	  }
	} # End for each subloc
      } elsif ($featChars->{$featid}->{'type'} eq 'CDS') { # If simple location
	my ($thisstart,$thisend)=($start,$end);
	my $thisexon=$featid.'_exon'.eval($numFragments+1);
	$featExons->{$featid}->{$thisexon}->{"start"}=$thisstart;
	$featExons->{$featid}->{$thisexon}->{"end"}=$thisend;
	$featExons->{$featid}->{$thisexon}->{"frame"}="unknown";
	    if ($partialStart) {
	      $featExons->{$featid}->{$thisexon}->{"start"}="<".$thisstart;
	    }
	    if ($partialEnd) {
	      $featExons->{$featid}->{$thisexon}->{"end"}=">".$thisend;
	    }
	my $frame=1;
	if ($strand==1) { $frame=($thisstart+2)%3; $frame=3 if ($frame==0); }
	if ($strand==-1) { $frame=($s_len-$thisend)%3; $frame=3 if ($frame==0); } $frame='-'.$frame;
	$featExons->{$featid}->{$thisexon}->{"frame"}=$frame;
	if ($strand==1 and ($pstarttype=~/BEFORE/ or $feat->location->to_FTstring()=~/</)) {
	  if ($feat->has_tag('codon_start')) {
	      my @csvals=$feat->get_tag_values('codon_start');
	      if (@csvals) {
	    	$featChars->{$featid}->{'codon_start'}=$csvals[0];
	    	$thisstart=$thisstart+$csvals[0]-1;
	      } else {
	       print "ERROR: $featid: CDS (start=$start, end=$end) seems to be a partial gene, but no codon_start has been specified. Translation might be incorrect!\n";
	       exit(1);
	      }
	  }
	}
	if ($strand==-1 and ($pendtype=~/AFTER/ or $feat->location->to_FTstring()=~/>/)) {
	  if ($feat->has_tag('codon_start')) {
	      my @csvals=$feat->get_tag_values('codon_start');
	      if (@csvals) {
	    	$featChars->{$featid}->{'codon_start'}=$csvals[0];
	        $thisend=$thisend-$csvals[0]+1;
	      } else {
	        print "ERROR: $featid: CDS (start=$start, end=$end) seems to be a partial gene, but no codon_start has been specified. Translation might be incorrect!\n";
	        exit(1);
	      }
	  }
	}
	my $thisfrag=$seqobj->subseq($thisstart,$thisend);
	$featExons->{$featid}->{$thisexon}->{"translation"}=BioUtils::translateDNA2Protein($thisfrag);;
	if ($strand==1) {
	  $protseq=$protseq.BioUtils::translateDNA2Protein($thisfrag);
	} else {
	  $protseq=BioUtils::translateDNA2Protein(Parser::revComp($thisfrag)).$protseq;
	}
      }
      $featChars->{$featid}->{"translation"}=$protseq;
      if (exists $feat->{'_gsf_tag_hash'}->{'product'}) {
        $featChars->{$featid}->{"product"}=join('',$feat->get_tag_values('product'));
      } else {
	print "Product does not exist for this feature of type $feattype and featid $featid\n";
      }
    } # End foreach feat

    # Write features for given sequence to GFF file
    foreach my $f (sort { $featStarts->{$a} <=> $featStarts->{$b} } (keys %{ $featStarts })) {

      # First print the CDS
      print OUTF "$s_disp_id","\t"; # Display ID of parent sequence
      print OUTF "$source","\t"; # Source of source
      print OUTF "$featChars->{$f}->{'type'}","\t"; # Type of feature
      print OUTF "$featChars->{$f}->{'start'}","\t"; # Start of feature
      print OUTF "$featChars->{$f}->{'end'}","\t"; # End of feature
      print OUTF ".","\t"; #Score
      print OUTF "$featChars->{$f}->{'strand'}","\t"; # Strand of feature
      # Phase of feature
      if (exists $featChars->{$f}->{'codon_start'}) {
	print OUTF "$featChars->{$f}->{'codon_start'}","\t";
      } else {
	print OUTF "0","\t";
      }
      # Feature attributes
      print OUTF "ID=$f";
      if ($featChars->{$f}->{'type'} eq 'CDS' or $featChars->{$f}->{'type'} eq 'exon') {
	print OUTF ";Translation=$featChars->{$f}->{'translation'}";
      }
      print OUTF "\n";

      # Then print its exons
      if (exists $featExons->{$f}) { foreach my $exon(sort keys %{ $featExons->{$f} }) {
	print OUTF "$s_disp_id","\t"; # Display ID of parent sequence
        print OUTF "$source","\t"; # Source of source
        print OUTF "exon","\t"; # Type of feature
        print OUTF "$featExons->{$f}->{$exon}->{'start'}","\t"; # Start of feature
        print OUTF "$featExons->{$f}->{$exon}->{'end'}","\t"; # End of feature
        print OUTF ".","\t"; #Score
        print OUTF "$featChars->{$f}->{'strand'}","\t"; # Strand of feature
	print OUTF ".","\t"; # Codon start of exon
	print OUTF "ID=$exon;Parent=$f;Frame=$featExons->{$f}->{$exon}->{'frame'};Pseudo==$featExons->{$f}->{\"pseudo\"};Translation=$featExons->{$f}->{$exon}->{'translation'}","\n";
      }}
    } # End write feature

  } # End foreach sequence

  system("cat $outputseqfile >> $outputf");
  system("rm $outputseqfile");

  close (OUTF);
}

# Get protein sequence for a given DNA sequence
1;
