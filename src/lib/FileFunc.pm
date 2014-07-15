package FileFunc;
use Exporter();
@ISA=qw(Exporter);
@EXPORT=qw(newReadFileHandle newWriteFileHandle newAppendFileHandle);
use strict;



sub newReadFileHandle{
	my ($filename)=@_;

	my $parent = ( caller(1) )[3]; 
	open (my $rfh,$filename) or 
		die "Cannot open file $filename for reading. Called from $parent\n";
	return $rfh;
}

sub newWriteFileHandle{
	my ($filename)=@_;

	my $parent = ( caller(1) )[3]; 
	open (my $wfh,">".$filename) or 
		die "Cannot open create $filename. Called from $parent\n";
	return $wfh;
}

sub newAppendFileHandle{
	my ($filename)=@_;

	my $parent = ( caller(1) )[3]; 
	open (my $wfh,">>".$filename) or 
		die "Cannot open file $filename for appending. Called from $parent\n";
	return $wfh;
}

1;