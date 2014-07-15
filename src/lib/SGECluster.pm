package SGECluster;

use Bio::Perl;
use strict;
use Cwd;

# runBlastOnCluster: Subroutine to run a Blast job on a cluster
# ARG0:	Directory in which to create files
# ARG1: Input file with sequences
# ARG2: Blast command along with database
# ARG3: Output file of blast reoprts
# ARG4: Number of sequences in each smaller file
# ARG5: Job ID

sub runBlastOnCluster {

  my $tool="runBlastOnCluster";
  my $wdir=$_[0];
  my $infile=$_[1];
  my $blastcommand=$_[2];
  my $outfile=$_[3];
  my $file_sequences=$_[4];
  my $jobid=$_[5];

  if (!($wdir=~/\/$/)) { $wdir.="/"; }

  if (!$infile or !$outfile or !$blastcommand or !$wdir) {
    die "$tool did not have all essential parameters\n";
  }


  my $in=Bio::SeqIO->new( '-file'=>$infile,'-format'=>'fasta');
  print "$tool: File $infile open\n";

  my $index=0; my $stream; my @cmds;

  print "$tool: Splitting $infile into smaller files\n";

  while(my $seq =$in->next_seq()) {
    if (int($index/$file_sequences)*$file_sequences == $index) {
      my $fafile=$wdir.$jobid.".".$index.".faa";
      #print "Writing to fa file $fafile\n";
      my $blast_out=$wdir.$jobid.".".$index.".blout";
      my $cdd_out=$wdir.$jobid.".".$index.".cdd";
      $stream=Bio::SeqIO->new('-file'=>">$fafile",'-format'=>'fasta');
      my $blast_cmd="$blastcommand -i $fafile -o $blast_out";
      push @cmds, [$fafile,$blast_cmd,$blast_out];		
    }
    $stream->write_seq($seq);
    $index ++;
  }

  for(my $c=0; $c<scalar(@cmds); $c++) {
    my $scriptFile=$cmds[$c][0].".sh";
    open (SCRIPT,">".$scriptFile) or die "Cannot open $scriptFile\n";
    print SCRIPT "#!/bin/bash\n";
    print SCRIPT "$cmds[$c][1]\n";
    close SCRIPT;
    my $mountcheck="ls /opt/uge/genepool/uge/genepool/common/ > /dev/null"; system($mountcheck);
    my $cmd="chmod 755 $scriptFile"; system($cmd);
    $cmd="qsub -cwd -V -l genepool_normal.c $scriptFile"; system($cmd);
    #$cmd="qsub -cwd -V -l long.c $scriptFile"; system($cmd);
  }

  # Consolidate results
  while (1) {
    my $mountcheck="ls /opt/uge/genepool/uge/genepool/common/ > /dev/null"; system($mountcheck);
    my $qjobs=`qstat -s pr`;
    if ($qjobs=~/failed receiving gdi request/) {
      sleep(600);
      print "Cluster error: $qjobs\n"; next;
    } elsif ($qjobs=~/commlib error/) { 
      sleep(600);
      print "Cluster error: $qjobs\n"; next;
    }
    my @qarr=split(/\n/,$qjobs);
    my $ended=1;
    #print "QJobs = $qjobs\n",scalar(@qarr),"\n";;
    foreach my $job (@qarr) {
    #print "Job=$job\nJObID=$jobid\n";
      if ($job=~/$jobid/) {
        $ended=0;
	#print "Job ID=$jobid, Ended set to zero\n";
	last;
      }
    }
    #print "Ended set to $ended\n";
    if ($ended==0) {
      sleep(600); next;
    } elsif ($ended==1) { # All jobs have ended, do cleanup and consolidation
      print "SGECluster: All jobs have ended\n";
      for(my $c=0; $c<scalar(@cmds); $c++) {
        my $scriptfile=$cmds[$c][0].".sh";
	my $seqfile=$cmds[$c][0];
	my $brfile=$cmds[$c][2];
	system("cat $brfile >> $outfile");
	unlink($scriptfile); unlink($seqfile); unlink($brfile);
      }
      # Now delete log files in the root directory
      my $currdir=getcwd();
      system("rm $currdir/$jobid.*.sh.[eo]*");
      last;
    }
  }

}

# runSingleSeqBlast: Run Blast for a single seq
# ARG0: Blast cmd str
# ARG1: Working directory for the genome
# ARG2: Job ID
sub runSingleSeqBlast {
  
  my $blaststr=$_[0]; my $wd=$_[1]; my $jobid=$_[2];

  my $scriptfile="$wd/$jobid"."m1blastscript.sh";
  open (SCRIPT,">".$scriptfile) or die "runSingleSeqBlast: Cannot open $scriptfile\n";
  print SCRIPT "#!/bin/bash\n";
  print SCRIPT "$blaststr\n";
  close SCRIPT;
  my $cmd="chmod 755 $scriptfile"; system($cmd);
  #$cmd="qsub -cwd -V -l long.c $scriptfile"; system($cmd);
  $cmd="qsub -cwd -V -l genepool_normal.c $scriptfile"; system($cmd);

  while (1) {
    my $qjobs=`qstat -s pr`;
    if ($qjobs=~/failed receiving gdi request/) {
      sleep(600);
      print "Cluster error: $qjobs\n"; next;
    } elsif ($qjobs=~/commlib error/) { 
      sleep(600);
      print "Cluster error: $qjobs\n"; next;
    }
    my @qarr=split(/\n/,$qjobs);
    my $ended=1;
    foreach my $job (@qarr) {
      if ($job=~/$jobid/) { $ended=0; last; }
    }
    if ($ended==0) {
      sleep(600); next;
    } elsif ($ended==1) { # All jobs have ended, do cleanup and consolidation
      my $scriptfile="$wd/$jobid"."m1blastscript.sh";
      unlink($scriptfile);
      # Now delete log files in the root directory
      my $currdir=getcwd();
      system("rm $currdir/$jobid*.sh.[eo]*");
      last;
    }
  }
}

1;
