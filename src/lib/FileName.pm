package FileName;
use Exporter();
@ISA=qw(Exporter);
@EXPORT=qw( randomFileName indexFile splitFileName);
use strict;
use warnings;
use TimeFunc;

#returns a random filename
sub randomFileName {
        my @time=TimeFunc::_currTimeArray(); # get the current time
        my $fname=$time[0]."_".$time[1]."_".$time[2];
        my $random1= int(rand(1000)); #generate a random number
        my $random2= int(rand(100)); #generate a random number
        my $random3= int(rand(1000)); #generate a random number
        $fname.=$random1."_".$random2."_".$random3;
        return $fname;
}


sub indexFile
{
        my %return_hash=();
        my ($filename,$indexCol,$valueCol,$comment)=@_;

        if(!defined($comment)){$comment=0;} # no comments in file
        if(!defined($indexCol)){$indexCol=0;}
        if(!defined($valueCol)){$valueCol=1;}

        if(!defined($filename)){return 0;}
        print STDERR "Indexing file $filename\n";
        open (INDEX,"<$filename") or return 0;
        {
                while (my $line=<INDEX>)
                {
                        chomp $line;
                        if($comment ==1 and $line=~/^#/) {next;} #skip comment lines
                        my @data=split("\t",$line);
                        if(!$data[$valueCol]){print STDERR "Cannot find a value for line :$line in file $filename\n";}
                        $return_hash{$data[$indexCol]}=$data[$valueCol];
                }
        }
        close INDEX;
        print STDERR "File $filename indexed\n";
        return \%return_hash;
}
# splits a filename. Returns the path and filename
sub splitFileName{
	
        my ($fn)=@_;
# 	print "splitFilename: processing $fn\n";
        my @path=split("/",$fn);
        my $filename=pop @path;
        my $path=join("/",@path);
        if(!defined($path) or $path eq ""){$path ='.';}
        # now separate the filename from extension
# 	print "splitFilename: $path / $filename\n";
        my @fnComp=split('\.', $filename);
        my $extension=pop @fnComp;
        my $fnBase=join('.',@fnComp);
        return($path,$filename,$fnBase,$extension);
}



1;
