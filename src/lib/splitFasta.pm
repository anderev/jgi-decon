package splitFasta;
use Exporter();
@ISA=qw(Exporter);
@EXPORT=qw(splitFasta);
use strict;
use warnings;
use Bio::SeqIO;
use FindBin;
use lib "$FindBin::Bin";
#use lib "/house/homedirs/k/kmavromm/Perl_lib";
use CommonFunc;
use Log::Log4perl;


#split a multi fasta file in N files
# places the new files in a new directory
# and updates an array with the generated file names
# returns the path to the temporary directory
sub splitFasta{
	
	my ($inFn,$number,$arrayRef,$format,$verbose)=@_;
	my $logger=Log::Log4perl->get_logger("splitFasta");
	if(!defined($verbose)){$verbose=0;}
	# assume fasta format if format is not given
	if(!defined($format)){$format='fasta';}
	#print "Splitting $format file $inFn into $number pieces\n";
	$logger->info("Input format ". $format);
	
	my @outStream;
	my @outStreamFn;
	my @ltempDir;
	my @fn;
	my ($path,$filename)=splitFn($inFn);
	# create a temporary file with the pieces 
	my $temporaryDir=$path."/splitFasta_$$";

	my $cmd="mkdir -p $temporaryDir";
	$logger->info( "Creating directory $temporaryDir\n") ;
	runCmd($cmd,0);
	$logger->info(" directory created\n") ;
	
	
	#create $number directory names
	$ltempDir[0]="$temporaryDir/0";
	for(my $i=1;$i<=$number;$i++){
		$ltempDir[$i]="$temporaryDir/$i";
# 		`mkdir -p $ltempDir[$i]`;
		$fn[$i]=$ltempDir[$i]."/".$filename;
# 		$outStream[$i]=Bio::SeqIO->new(-file=>">$fn",-format=>$format);
# 		$outStreamFn[$i]=$fn;
		
	}
	
	# place the files in the directories
	my $inStream=Bio::SeqIO->new(-file=>$inFn,-format=>$format);
	my $counter=1;
	my %dirCreated;

	while(my $seq=$inStream->next_seq()){
		
		if( $counter > $number){$counter =1;}
		if(!defined( $dirCreated{ $ltempDir[ $counter ] } )){
			my $cmd="mkdir -p ".$ltempDir[ $counter ];
			runCmd($cmd);
			$logger->debug("Created subdirectory ".$ltempDir[ $counter ] );
			$dirCreated{ $ltempDir[ $counter ] }=1;
			$outStream[$counter]=Bio::SeqIO->new(-file=>">$fn[$counter]",-format=>$format);
			$outStreamFn[$counter]=$fn[$counter];
			
		};
		$logger->debug("Placing ",$seq->display_name(), " into directory $ltempDir[ $counter ]");
		
# 		print "Placing ",$seq->display_name(), " into directory $ltempDir[ $counter ]\n";
		
		$outStream[$counter]->write_seq($seq);
		@{$arrayRef}[$counter]=$outStreamFn[$counter];
		$counter ++;
# 		last;
	}
	
	# delete the directories that are empty
	for(my $i=1;$i<=$number;$i++){
		if(defined($dirCreated{$ltempDir[$i]})){next;}
		my $cmd="rm -rf ".$ltempDir[$i];
		runCmd($cmd);
		$logger->debug("Cleaning empty directory ". $ltempDir[$i]);
	}

	return $temporaryDir;
}



1;
