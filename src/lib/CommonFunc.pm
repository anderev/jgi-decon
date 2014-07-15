package CommonFunc;
use Exporter();
@ISA=qw(Exporter);
@EXPORT=qw(runReverseAln
ShowProgressWheel 
ShowProgressMessage 
reverseComplement 
isOverlapping 
sendEmail 
swap 
currTime 
currTimeArray 
randomFname 
indexFn 
runMUSCLE 
runMultAlin runDiAlign runCLUSTAL calcConsensus 
splitFn getGeneSequence getGenomeSeqObj getTaxonDir wrapSeq random_number runCmd);
use strict;
use FindBin qw( $RealBin );
use lib $RealBin;
use FileFunc;
use FileName;
use TimeFunc;
use warnings;
use Bio::Perl;

{
	my $counter;
	my $stringLen;
	sub ShowProgressWheel{
   
		$|=1;
		my @animation = qw( \ | / - );
		print "$animation[$counter++]\b";
		$counter=0 if $counter==scalar(@animation);
	}
}
sub ShowProgressMessage{
	my ($value)=@_;
	
	chomp $value;
#	my $string=sprintf( "%.6d",$value);
	my $string=$value;
	$|=1;

	my $size=length($string);
	print "$string";
	for(my $i=0;$i<$size; $i++){print "\b";}
}

sub runCmd{
	my ($cmd,$verbose)=@_;
	if(!defined($verbose)){$verbose=0;}
	if($verbose>0){ warn "Executing command: $cmd\n";}
	system($cmd);
	if ($?) {die "command: $cmd failed\n"};
}

#wrap a string to multiple lines of length wrapLen
sub wrapSeq{
   my( $seq, $wrapLen ) = @_;

   if( !defined($wrapLen) or $wrapLen eq "" ) {
      $wrapLen = 50;
   }
   my $i;
   my $s2;
   my $len = length( $seq );
	if ($len == 0){return $seq;}
   for( $i = 0; $i < $len; $i += $wrapLen ) {
       my $s = substr( $seq, $i, $wrapLen );
       $s2 .= $s . "\n";
   }

   chomp $s2;
   return $s2;
}



# get the directory of the sequences of a taxon
sub getTaxonDir{
	my ($taxon_oid, $verbose)=@_;
	
	if(!$verbose){$verbose=0;}
	my @directory_prefix=
		("/house/groupdirs/img/archive/eszeto/web/data/all.fna.files/",
		 "/house/groupdirs/img/archive/eszeto/web/data/all.fna.files/$taxon_oid/",
		 "/home/img7/eszeto/web/data/img_i_v2x/taxon.fna/",
		 "/house/groupdirs/img/normal/eszeto/web/data/taxon.fna/",
		"/house/groupdirs/img/archive/krishnap/dataLoad_3.1/all.fna.files",
		"/house/groupdirs/img/archive/krishnap/dataLoad_3.1/all.fna.files/$taxon_oid/",
		"/house/groupdirs/img/archive/krishnap/dataLoad_3.2/all.fna.files/",
		"/house/groupdirs/img/archive/krishnap/dataLoad_3.2/all.fna.files/$taxon_oid/",
		"/house/groupdirs/img/archive/krishnap/dataLoad_3.3/all.fna.files/",
		"/house/groupdirs/img/archive/krishnap/dataLoad_3.3/all.fna.files/$taxon_oid/",
		"/house/groupdirs/img/archive/krishnap/dataLoad_3.4/all.fna.files/",
		"/house/groupdirs/img/archive/krishnap/dataLoad_3.4/all.fna.files/$taxon_oid/",
		"/house/groupdirs/img/archive/krishnap/dataLoad_3.5/all.fna.files/",
		"/house/groupdirs/img/archive/krishnap/dataLoad_3.5/all.fna.files/$taxon_oid/",
		"/house/groupdirs/img_osf/archive/krishnap/dataLoad_3.1/all.fna.files/$taxon_oid/",
		"/house/groupdirs/img_osf/archive/krishnap/dataLoad_3.2/all.fna.files/$taxon_oid/",
		"/house/groupdirs/img_osf/archive/krishnap/dataLoad_3.3/all.fna.files/$taxon_oid/",
		"/house/groupdirs/img_osf/archive/krishnap/dataLoad_3.4/all.fna.files/$taxon_oid/".
		"/house/groupdirs/img_osf/archive/krishnap/dataLoad_3.5/all.fna.files/$taxon_oid/"
		
		);
	foreach my $directory_prefix(@directory_prefix){
		if(! -d $directory_prefix){next;}
		my $filename=$directory_prefix.$taxon_oid.".fna";	
		print "getTaxonDir: Looking for $filename\n" if $verbose ==1;
		if( $directory_prefix !~/$taxon_oid/ and ! -e  $filename and ! -d $filename ){
#			print "Found $filename \n" if $verbose ==1;
			next;
		}
		return $directory_prefix;
	};
}


# create a file which contains all the contigs of a genome
sub getGenomeSequenceFile{
	my ($taxon_oid, $verbose)=@_;
	
	if(!$verbose){$verbose=0;}
# 	print "verbose is $verbose\n";
	my $filename;
	print "getGenomeSequenceFile: Looking for the directory for taxon $taxon_oid\n" if $verbose==1;
	my $directory_prefix=getTaxonDir($taxon_oid, $verbose);
	print "getGenomeSequenceFile: For taxon $taxon_oid the directory is $directory_prefix\n" if $verbose ==1;
	$filename=$directory_prefix.$taxon_oid.".fna";	
	my $errCode=0;
	if(!-e $filename){$errCode=1;}
	`mkdir -p tmp`;
	if($directory_prefix=~/$taxon_oid/){
		my $cmd="cat $directory_prefix/* > tmp/$taxon_oid";
		runCmd( $cmd ) ;
		`mkdir -p tmp`;
		$filename= "tmp/$taxon_oid";
		$errCode=0;
	}else{$errCode++;}
	print "getGenomeSequenceFile: the filename is $filename\n" if $verbose==1;
	return $filename;
}


# this routine retrieves the genome nt sequence as a Bioperl sequence object from
# the taxon_oid
sub getGenomeSeqObj{
	my ($taxon_oid, $verbose)=@_;
	if(!$verbose){$verbose=0;}
# 	print "verbose is $verbose\n";
	my $filename;
	print "getGenomeSeqObj: Looking for the directory for taxon $taxon_oid\n" if $verbose==1;
	my $directory_prefix=getTaxonDir($taxon_oid, $verbose);
	print "getGenomeSeqObj: For taxon $taxon_oid the directory is $directory_prefix\n" if $verbose ==1;
	$filename=$directory_prefix.$taxon_oid.".fna";	
	print "getGenomeSeqObj: the genome filename is $filename\n" if $verbose==1;
	my $errCode=0;
	if(-e $filename){
		
	}elsif($directory_prefix=~/$taxon_oid/){
		my $cmd="cat $directory_prefix/* > tmp/$taxon_oid";
		runCmd( $cmd ) ;
		$filename= "tmp/$taxon_oid";
		$errCode=0;
	}else{
		$errCode++;
	}
	
	if($errCode > 0){ print STDERR "getGenomeSeqObj: Cannot find the genome file for genome $taxon_oid\n"; return;}
	
	my $in=Bio::SeqIO->new( '-file'=>$filename,'-format'=>'fasta');
	if($verbose ==1){print "getGenomeSeqObj: Genome $taxon_oid in file $filename\n";}
	return $in;
}



# get a subsequence from a seq_object. 
# and returns the string of the subsequence
{ my $seq;
sub getGeneSequence{
	my($seqObj,$ext_accession,$gene_start,$gene_end,$gene_strand, $verbose)=@_;

	if ($gene_strand eq '+'){$gene_strand =1;}
	elsif ($gene_strand eq '-'){$gene_strand=-1;}
	
	if(!defined($gene_strand)) {
		print STDERR "Strand $gene_strand is not recognized\n";
		return "";
	}
	my $found=0;
	my $sequence;

	
	if($seq and $seq->display_id() eq $ext_accession){}
	else{
		while( $seq =$seqObj->next_seq() )
		{
			if ($seq->display_id() eq $ext_accession){last;}
		}
	}	
	if ($seq and $seq->display_id() eq $ext_accession)
	{
		$found=1;
		if ($gene_start<=0){$gene_start=1;}
		if ($gene_end > $seq->length()){
			print STDERR "For gene in ",$seq->display_name()," $gene_start - $gene_end ($gene_strand) ";
			print STDERR "Adjusting ending coordinate from $gene_end to ", $seq->length(),"\n";
			$gene_end=$seq->length();}
		if($gene_start> $gene_end){
			print STDERR "For gene in ",$seq->display_name()," $gene_start - $gene_end ($gene_strand) ";
			print STDERR "Coordinates $gene_start ... $gene_end do not have correct orientation $ext_accession\n";
			return;
		}
		my $location = new Bio::Location::Simple(-start  =>$gene_start,-end    => $gene_end,-strand => $gene_strand );
		$sequence=$seq->subseq($location);
		return $sequence;
	}
	
	if ($found == 0 ){print STDERR "Cannot find scaffold $ext_accession \n" if $verbose and $verbose ==1 ;return "";}
}
}
sub currTime
{
my $theTime=TimeFunc::_currTime();
return $theTime;

}

#returns the time in an array
sub currTimeArray
{
my @theTime = TimeFunc::_currTimeArray();
return @theTime;

}






sub runMUSCLE{
	my ($filename,$outfilename)=@_;
	
	my $bin='/jgi/tools/bin/muscle -quiet ';
	
	my $cmd=$bin."-in $filename -out $outfilename";
# 	print "$cmd\n";
	system($cmd);
}
sub runReverseAln{
	my ($filename,$alnFile,$proteinAlnFn)=@_;
		
	my $bin='java -cp /home/kmavromm/house/SourceCode/Prot2NucAlignment Prot2NucAlignment ';
	my $cmd= $bin. " -n $filename -p $proteinAlnFn -o $alnFile ";
	runCmd($cmd);
}


sub runCLUSTAL{
	my ($filename,$outfilename)=@_;
	my $bin='/jgi/tools/bin/muscle -quiet -clwstrict ';
	my $cmd=$bin."-in $filename -out $outfilename";
# 	print "$cmd\n";
	system($cmd);
}

sub runMultAlin{
	my($inputFn, $outputFn)=@_;
	my $aligner="/jgi/tools/bin/ma";
	my $alignCmd="$aligner ".
			"-i:mul -o:mul -a -A -c:/jgi/tools/misc_software/multalin/DEFAULT/blosum62.tab ".
			"$inputFn ";
		
	system($alignCmd);
	my ($path,$fn, $base,$ext)=splitFn($inputFn);
	#by default the output is $path/$base.mul
	# we need to remove the proxy gene sequence to avoid 

	my $moveCmd="mv $path/$base.mul $outputFn";
	system($moveCmd);
	
	unlink("*.mfa");
	unlink("*.con");
	unlink("*.clu");
	unlink("*.cl2");
}

sub runDiAlign{
	my($inputFn, $outputFn, $verbose)=@_;
	if(!$verbose){$verbose=1;}
	my $aligner="~gbp/programs/dialign_package/dialign2-2";
	my $alignCmd="$aligner ".
			" -fa ".
			"$inputFn ";
		
	system($alignCmd);
# 	my ($path,$fn, $base,$ext)=splitFn($inputFn);
	#by default the output is $inputFn.fa
	# we need to remove the proxy gene sequence to avoid 

	my $moveCmd="mv $inputFn.fa $outputFn";
	system($moveCmd);
	if($verbose ==1){
		unlink("$inputFn.ali");
	}

}


#calculate the consensus of the sequence alignment
# the parameter seq defines if the sequence is protein or nt
sub calcConsensus{
	my ($filename,$output,$seq)=@_;
	if (!$seq){$seq='protein';}
	my $bin='cons ';
	my $datafile;
	if ($seq eq 'protein'){$datafile="/jgi/tools/misc_bio/emboss/DEFAULT/share/EMBOSS/data/EBLOSUM62";}
	if ($seq eq 'nucleic'){$datafile="/jgi/tools/misc_bio/emboss/DEFAULT/share/EMBOSS/data/EDNAFULL";}
	my $cmd=$bin."-sequence $filename -outseq $output -plurality 0.2 -identity 1 -datafile $datafile";
# 	print "$cmd\n";
	system ($cmd);
}


#swap the values of two variables
sub swap{
	my ($var1,$var2)=@_;
	my $temp=$var2;
	$var2=$var1;
	$var1=$temp;
	return($var1,$var2);
}



# routine to generate a list of random numbers within a population
# start , end are the first and last index no of a population
# limit is the number of elements to be returned.
sub random_number
{
        my ($start_number,$end_number,$Limit)=@_;
        my @list;
        my %used;

#       print STDERR "Random Number: ",scalar(@list)," elements were loaded in the first pass out of $Limit\n";
        # the total number of random elements must be = $Limit
        # if not pick some random numbers and add them to the array
        my $range=$end_number-$start_number;
        while(scalar(@list)<$Limit){
                my $intRand = int(rand($range))+1+$start_number;
                if(! $used{$intRand}){
                        push @list,$intRand;
                        $used{$intRand}=1;
                }
        }
#       @list=Array_Routines::unique(\@list,1);
#       print STDERR "Random Number: ",scalar(@list)," elements were loaded in the first pass out of $Limit\n";
        return @list;
}



sub sendEmail{
	my ($recipients,$subject,$message)=@_;
	my $tmp="/tmp/".$$."_message.txt";
# 	print STDERR "Sending message $message to users @{$recipients}\n";
	open (MESSAGE,">$tmp") or die ("Cannot open $tmp\n");
	print MESSAGE $message;
	close MESSAGE;
	my $cmd="/usr/bin/mail ".join(' ',@{$recipients});
	$cmd.=" -s '$subject' < $tmp";
	system($cmd);
# 	print STDERR $cmd."\n";
	unlink ("$tmp");
}



# decide if two sets of coordinates overlap
sub isOverlapping{
	my ($s1,$e1,$s2,$e2)=@_;
	my $verbose=1;
	my $overlap=0;
	if ($e1< $s1){ ($s1,$e1)= swap($s1,$e1);}
	if ($e2< $s2){ ($s2,$e2)= swap($s2,$e2);}



	if($s2<= $s1 and $e2>= $e1){ $overlap= $e1-$s1 +1;}
	if($s2>= $s1 and $e2<= $e1){ $overlap= $e2-$s2 +1;}
	if($s1<= $s2 and $e1>= $s2 and $e1<= $e2){$overlap= $e1-$s2+1;}
	if($s1>= $s2 and $s1<= $e2 and $e1>= $e2){$overlap= $e2-$s1+1;}
	
 	print "isOverlapping:  $s1 - $e1 with $s2 - $e2 overlap $overlap\n" if $verbose==1;
	return $overlap;
}


# return the reverse complement of aa DNA string
sub reverseComplement{
	my ($sequence)=@_;
	my $revcom = reverse $sequence;
	$revcom =~  tr/ACGTacgt/TGCAtgca/;
	return $revcom;

}

###################################################################################
###################################################################################
# FileName routines
###################################################################################
###################################################################################

#returns a random filename
sub randomFname {
	return randomFileName();
}
# splits a filename. Returns the path and filename
sub splitFn{
	
	my ($fn)=@_;
	my ($path,$filename,$fnBase,$extension)=splitFileName($fn);
	return($path,$filename,$fnBase,$extension);
}
# reads a file and returs a hash table
# filename is the name "absolute path" of the tab delimited file
# IndexCol is the col that will become the key to the hash
# ValueCol is the col that contains the values that will be added to the hash
# indexCol and ValCol start from 0
# Comments if 1 then lines starting with the "#" will be omitted
# If an index contains more than one value only the last value will be returned
# return 0 if file does not exist
# or a POINTER to a hash
sub index{
	my $return_hash;
	my ($filename,$indexCol,$valueCol,$comment)=@_;
	if(!$comment){$comment=0;}
	$return_hash=indexFn($filename,$indexCol,$valueCol,$comment);
	return $return_hash;
}


sub indexFn
{
	my ($filename,$indexCol,$valueCol,$comment)=@_;
	my $ref= FileName::indexFile($filename,$indexCol,$valueCol,$comment);
	return $ref;
}

1;
