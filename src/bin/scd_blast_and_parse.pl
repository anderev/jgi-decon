#!/usr/bin/env perl

# Script to run a blast job and parse the results
# distributes the blast job on cluster nodes

use strict;
use FindBin ();
use lib "$FindBin::Bin";
use lib "$FindBin::Bin/../lib";
use QAJobs;
use Bio::Perl;
use Getopt::Long;
$Getopt::Long::ignorecase=0;
use Cwd;
use splitFasta;
use CommonFunc;
use FileFunc;

my $current_dir=getcwd()."/";
my $tool='blast';
my $sleepTime=300;
my $inputfilename;
my $databaseFn;
my $file_sequences=50;
my $small_files;
my $blastcommand;
my $finalOut; my $finalParsedOut;
my $queue="normal.c";
my $jobname;
my $qsubstr;
my $installpath;
my $overrideSplit;
my $selfname;
my $workdir;
my $blast_threads;

$^W=0;

my $blastCmd = defined $ENV{BLASTALL_EXE} ? $ENV{BLASTALL_EXE} : 'blastall';

GetOptions(     "i=s" => \$inputfilename,
                "d=s" => \$databaseFn,
		"f=s" => \$small_files,
		"n=s" => \$file_sequences,
		"b=s" => \$blastcommand,
		"q=s" => \$queue,
		"j=s" => \$jobname,
		"p=s" => \$installpath,
		"o=s" => \$finalOut,
		"g=s" => \$qsubstr,
		"w=s" => \$workdir,
		"a=s" => \$blast_threads,
		"op=s" => \$finalParsedOut,
		"split=s"=>\$overrideSplit,
		"sleep=i"=>\$sleepTime	);

sub printUsage{
	print "Compulsory arguments to use $0 \n".
		"-i sequences \n".
		"-d database \n".
		"-n [sequences in each file] | -f [total number of output files] \n".
		"-o output \n".
		"-op parsed output \n".
		"-b 'tool command' (in single quotes) \n".
		"-j jobname for qsub \n".
		"-g qsub string with ram, time, and group \n".
		"-p install path of scd \n".
		"-w working directory \n".
		"-a blast processors to use \n".
		"-q queue name for cluster [default $queue]\n";
	print "$0 separates the sequence file into smaller sequence files and runs blast.\n";
	print "If you use blast/uclust it will use the parallel environments and submit to pe_8\n";
}

if (!$inputfilename or !$finalParsedOut or !$finalOut ) {
  printUsage(); exit 1;
}

unless($qsubstr){
	$qsubstr=" -pe pe_slots 8 -l normal.c -l h_rt=12:00:00 ";
}

unless($blast_threads){
        $blast_threads=8;
}

my $blastparser=$installpath . "/bin/scd_blast_parser.pl";

if($inputfilename!~/^\//) { $inputfilename=$current_dir. $inputfilename; }

my @databases;
foreach my $database(split(",", $databaseFn)) {
	if($database!~/^\//){$database=$current_dir. $database;};
	push @databases,$database;
}

if ($finalOut!~/^\//) { $finalOut=$current_dir. $finalOut; };
if ($overrideSplit and $overrideSplit!~/^\//) { $overrideSplit=$current_dir. $overrideSplit; } 

print STDERR "Finding number of sequences in database $inputfilename file\n";
my $total=`/bin/grep '^>' $inputfilename -c `;
chomp $total;
print STDERR "The file $inputfilename contains $total sequences\n";

if (defined($file_sequences) and !defined($small_files)) {
  $small_files=$total/$file_sequences;
  $small_files=1+int($small_files) if (int($small_files) != $small_files);
}
print STDERR "We will split the sequences to $small_files pieces\n";

my ($path,$fn)=splitFn($inputfilename);

my $tempDir; my @filenames;
if (!defined($overrideSplit)) {
  print STDERR "Splitting the fasta file\n";
  $tempDir=splitFasta($inputfilename,$small_files,\@filenames,'fasta');
} else {
  if (! -d $overrideSplit){ die "$overrideSplit is not a valid directory\n"; }
  $tempDir= $overrideSplit;
  foreach my $f ( `ls $tempDir` ) {
    chomp $f;
    if (! -d $f) { next; }
    my ($d,$n)=splitFn( $inputfilename );
    push @filenames, $tempDir."/".$f."/".$n;
  }
}

shift(@filenames);
#print "Filenames are ",join(" ",@filenames),"\n";
print "Array size=",scalar(@filenames),"\n";

if ($tempDir =~/^\./) { $tempDir= $current_dir."/$tempDir"; }

my $databaseCounter=0; my $submissionCounter=1;
foreach my $database( @databases ){
	$databaseCounter ++;
	foreach my $f(@filenames){
		print "Processing file $f with database $database\n";
		my ($tdir,$fn)=splitFn($f);
		
		my $blast_out=$f.$databaseCounter.".blout";
		my $parsed_blast_out=$f.$databaseCounter.".pblout";
		my $eukcontigfile=$f.$databaseCounter.".euks.contigs";
		my $successFn= $f.$databaseCounter.".SUCCESS";
		my $failureFn= $f.$databaseCounter.".FAILURE";
		my $blast_cmd;

		$fn = $submissionCounter.".".$fn;

		my $sinputFn="/scratch/$fn";
		my $sblast_out="/scratch/$fn.output";
		my $sparsed_blast_out="/scratch/$fn.pbr";
		my $seukcontigfile="/scratch/$fn.euks.contigs";
		$blast_cmd="$blastCmd -p blastx -d $database -i $sinputFn -a $blast_threads -o $sblast_out -b 2 -v 2 -e 0.001";
		#my $scriptFile=$tdir . "/job_". $fn .".$$.$databaseCounter.sh";
		my $scriptFile=$tdir . "/job.sh";
		
		#my $qsubcmd="qsub -n scd -pe pe_slots 8 -o $tdir/log -j y -R y -V -l $queue -l h_rt=12:00:00 ";
		#$qsubcmd .="$scriptFile";
		open (SCRIPT,">".$scriptFile)||die "Cannot open $scriptFile\n";
		print SCRIPT "#!/bin/bash\n".
			"ls /opt/uge/genepool/uge/genepool/common/settings.sh >/dev/null\n".
			"cp $f $sinputFn\n".
			"echo -n 'Start time: '> $scriptFile.time \n".
			"date >> $scriptFile.time\n".
			#"module load blast\n".
			"$blast_cmd\n".
			"echo -n 'End blast time: ' >> $scriptFile.time \n".
			"date >>$scriptFile.time\n".
			"$blastparser $sblast_out $sparsed_blast_out $seukcontigfile $installpath\n".
			"echo -n 'End parse time: ' >> $scriptFile.time \n".
			"date >>$scriptFile.time\n".
			'if [ $? -eq 0 ] && [ -f '. $sblast_out. ' ]  ; then'."\n".
			"cp  $sblast_out $blast_out \n".
			"cp  $sparsed_blast_out $parsed_blast_out \n".
			"cp  $seukcontigfile $eukcontigfile \n".
			"touch ". $successFn ."\n".
			"else\n".
			"touch ". $failureFn ."\n".
			"fi\n".
			"if [ -e $sblast_out ]; then\n".
			"echo 'File $sblast_out found '>> $successFn\n".
			"else\n".
			"echo 'Could not find file $sblast_out' >>$failureFn\n".
			"fi\n".
			"rm $sinputFn\n".
			"rm $sblast_out\n";
			
		close SCRIPT;
		my $cmd="chmod 755 $scriptFile";
		system($cmd);
		$cmd="ls /opt/uge/genepool/uge/genepool/common/settings.sh >/dev/null";
		system($cmd);
	
		#system($qsubcmd);
		$submissionCounter++;
		print "Submission $submissionCounter.\n";
		if($submissionCounter % 200 ==0){ 
			print "Waiting for 10'' before we continue. 
			We don't want to overwhelm the submission queue\n";
			sleep( 10); 
		}
	}
}

# Create task file
my $jsh=$tempDir."/"."runJ.sh";
open (T,">$jsh")
  or die "Couldn't open $jsh to write\n";
print T "#!/bin/bash\n\n";
print T "$tempDir/\$1/job.sh";
close (T);
system("chmod +x $jsh");

# Create task array file
system("mkdir $tempDir/log");
$submissionCounter--;
my $jash=$tempDir."/"."runJA.sh";
open (J,">$jash")
  or die "Couldn't open $jash to write\n";
print J "#!/bin/bash\n\n";
print J "echo host \$HOSTNAME\n";
print J "echo sge_task_id \$SGE_TASK_ID\n\n";
print J "$tempDir/runJ.sh \$SGE_TASK_ID\n\n";
#my $qsubcmd="qsub -t 1-$submissionCounter -N scd$jobname -pe pe_slots 8 -o $tempDir/log -j y -R y -V -l $queue -l h_rt=2:00:00 $jash";
my $qsubcmd="qsub -t 1-$submissionCounter -N scd$jobname -o $tempDir/log -j y -R y -V $qsubstr $jash";
#print J "# This script was submitted to $queue using the command \n".
print J "# This script was submitted using the command \n".
					 "# $qsubcmd\n";
close (J);
system("chmod +x $jash");

#system ($qsubcmd);
my $jobnum=`$qsubcmd`;
$jobnum=~/([0-9]+)/;
$jobnum=$1;
my $jcmd="touch " . $workdir . "/" . $jobnum;
system($jcmd);

for (;;) {
  sleep($sleepTime);
  $databaseCounter=0;
  my $counter=0;
  foreach my $database(@databases) {
	$databaseCounter++;
	my $logFh=newWriteFileHandle($tempDir."/blast_cluster.log");
	foreach my $f (@filenames) {
		my ($tdir,$fn)=splitFn($f);
		my $blast_out=$f.$databaseCounter.".blout";
		my $parsed_blast_out=$f.$databaseCounter.".pblout";
		my $successFn= $f.$databaseCounter.".SUCCESS";
		my $failureFn= $f.$databaseCounter.".FAILURE";
		my @str;
		print "Looking for files $successFn and $blast_out. Database counter is $databaseCounter\n";
		if (-e $successFn and -e $blast_out) { $counter ++; }
		else { push @str,$f; }
		if ($counter == scalar(@filenames)*scalar(@databases)) {
		  print $logFh " $counter / ", scalar(@filenames), " success files were found for $database\n";
		  print $logFh "   Proceeding with merging files\n";
		  last;
		} else {	
		  print $logFh " $counter / ", scalar(@filenames), " success files were found for $database\n";
		  print $logFh "   Still waiting for :\n",join("\n",@str),"\n" if $counter >0;
		}
	}
	print "Counter=$counter\n";
	close $logFh;
  }
  if ($counter == scalar(@filenames)*scalar(@databases)) { last; }
}

$databaseCounter=0;
foreach my $database (@databases) {
	$databaseCounter ++;
	foreach my $f (@filenames) {
		my ($tdir,$fn)=splitFn($f); $tdir=~/^.+\/(\d+)$/; my $cntr=$1;
		#my $scriptFile=$tdir . "/job_". $fn .".$$.$databaseCounter.sh";
		my $timeFile=$tdir . "/job_$cntr.". $fn .".$$.$databaseCounter.sh.time";
		my $blast_out=$f.$databaseCounter.".blout";
		my $parsed_blast_out=$f.$databaseCounter.".pblout";
		my $cmd="cat $blast_out >> $finalOut; cat $parsed_blast_out >> $finalParsedOut; cat $timeFile >> $finalOut.time;";
		print "Executing $cmd\n";
		system($cmd);
	}
}

$jcmd="rm " . $workdir . "/" . $jobnum;
system($jcmd);

print "Removing temporary directory $tempDir";
if( -d $tempDir ){ `rm -rf $tempDir`;}
