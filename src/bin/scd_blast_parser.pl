#!/usr/bin/env perl

use strict;

my $usage="$0 <input-m0 blast multireport> <output-parsed blast file> <output-euk contigs file> <install location>\n";

@ARGV==4
  or die $usage;

my ($m0out,$parsedf,$eukcf,$installpath)=@ARGV;

my $euks_f="$installpath/lib/euks.txt";
my $proks_f="$installpath/lib/proks.txt";

my $euks='';
open (EF,$euks_f)
  or die "$0: Couldn't open $euks_f to read\n";
while (<EF>) {
  my $l=$_; chomp ($l);
  $euks.=":".$l;
}
close (EF);

my $proks='';
open (PF,$proks_f)
  or die "$0: Couldn't open $proks_f to read\n";
while (<PF>) {
  my $l=$_; chomp ($l);
  $proks.=":".$l;
}

my ($qname,$sname) = ('','');
my ($qchanged,$schanged,$hchanged) = (0,0,0);
my ($qnaming,$snaming,$qlen,$slen) = (0,0,0,0);
my ($qstart,$qend,$sstart,$send) = (-1,-1,-1,-1);
my ($bits,$expect,$length,$ident,$positives,$gaps,$frame) = (-1,'',-1,-1,-1,-1,'');
my ($n_queries,$n_hits) = (0,0);
my $eukgs={}; my $eukcs={}; my $validhitcnt=0; my $qhits={}; my $euk=0;

open (BR,$m0out);
my $outf;
open ($outf,">$parsedf");
while (<BR>)
{
    chomp;
    if ($qnaming)
    {
        if ($_ =~ /^\s*Length=(\d+)$/ or $_ =~ /^\s*\((\d+) letters\)$/)
        {
            $qlen = $1;
            $qnaming = 0;
            #print STDERR "Query = $qname\n";
            #print STDERR ">";
        }
        else { $qname .= " $_"; }
        next;
    }

    if ($snaming)
    {
        if (/^\s*Length\s*=\s*(\d+)$/)
        {
            $slen = $1;
            $snaming = 0;
            #print STDERR "    Subject = $sname\n";
            #print STDERR ":";
        }
        else { s/^\s+//; $sname .= " $_"; 
	  my $eukc=isEuk($qname,$sname,$ident);
	  #if ($eukc=~/^contig.*/) { print "returned $eukc\n"; }
	  if ($eukc) {
	    print "Found euk contig $eukc hitting $sname\n";
	    $eukcs->{$eukc}=1;
	    $euk++;
	  } else { ; }
	}
        next;
    }

    if (/^Query[\:\s]\s(\d+)\s.*\s(\d+)$/)
    {
        if ($qstart < 0 or $1 < $qstart) { $qstart = $1; }
        if ($qend < 0 or $1 > $qend) { $qend = $1; }
        if ($2 < $qstart) { $qstart = $2; }
        if ($2 > $qend) { $qend = $2; }
        next;
    }

    if (/^Sbjct[\:\s]\s(\d+)\s.*\s(\d+)$/)
    {
        if ($sstart < 0 or $1 < $sstart) { $sstart = $1; }
        if ($send < 0 or $1 > $send) { $send = $1; }
        if ($2 < $sstart) { $sstart = $2; }
        if ($2 > $send) { $send = $2; }
        next;
    }

    if (/^\sScore/)
    {
	#print "Parsing score for $qname\n";
        if ($snaming) { print STDERR "Error: can't complete subject name: $sname\n"; next; }
        if ($qnaming) { print STDERR "Error: can't complete query name: $qname\n"; next; }
#        &flush_hit($outf);
#print "1:Expect=$expect\n";
&flush_hit($outf) if ($expect<=0.001);
        ($qstart,$qend,$sstart,$send) = (-1,-1,-1,-1);
        ($bits,$expect,$length,$ident,$positives,$gaps,$frame) = (-1,'',-1,-1,-1,-1,'');

        if (/^\sScore\s+=\s+([\d\+e\.]+)\s+bits/) { $bits = int($1); } else { print STDERR "Error: Can't parse score: \"$_\"\n"; }
        if (/\s+Expect\(?\d*\)?\s+=\s+([e\-0-9\.]+)/) { $expect = $1; } else { print STDERR "Error: Can't parse expectation: \"$_\"\n"; }
        $hchanged = 1;
        next;
    }

    if (/^\sIdentities/)
    {
        ($length,$ident,$positives,$gaps,$frame) = (-1,-1,-1,-1,'');
        if (/^\sIdentities\s+=\s+(\d+)\/(\d+)\s+\(\d+\%\)/)
        {
            ($ident,$length) = ($1,$2);
        }
        if (/\s+Positives\s+=\s+(\d+)\/\d+\s+\(\d+\%\)/)
        {
            ($positives) = ($1);
        }
        if (/Gaps\s+=\s+(\d+)\//)
        {
            $gaps = $1;
        }
        else
        {
            $gaps = 0;
        }
        if ($length < 0)
        {
            print STDERR "Error: unexpected BLAST ' Identities = ' line format: $_\n";
        }
        next;
    }

    if (/\s[Ff]rame\s=\s(\S+)$/)
    {
	#print "Parsing frame for $qname\n";
        $frame = $1;
        if ($frame !~ /^(-?\+?\d|-?\+?\d\/-?\+?\d)$/) { print STDERR "Error: Unexpected frame: \"$frame\"\n"; }
        next;
    }

    if (/\sStrand\s=\s(\S+)$/)
    {
	#print "Parsing strand for $qname\n";
        $frame = $1;
        if ($frame !~ /^Plus\/(Plus|Minus)$/) { print STDERR "Error: Unexpected strand: \"$frame\"\n"; }
        next;
    }

    if (/^Query=\s+(.+)$/)
    {
	#print "Writing output for query $qname\n";
        my $new_qname = $1;
	if ($euk==2) {
	  open (EC,">>$eukcf")
    	    or die "$0: Couldn't open $eukcf to write\n";
	  foreach my $k (keys %{ $eukcs }) {
  	    print EC $k,"\n";
	  }
	  close (EC);
	}
	$euk=0;
#        &flush_hit($outf);
#print "2:Expect=$expect\n";
&flush_hit($outf) if ($expect<=0.001);
        $qname = $new_qname;
        $qnaming = 1;
        $qchanged = 1;
        $n_queries++;
        next;
    }

    if (/^>(.+)$/)
    {
	#print "Writing output for sub $sname\n";
        my $new_sname = $1;
#print "3:Expect=$expect\n";
&flush_hit($outf) if ($expect<=0.001);
#        &flush_hit($outf);
        $sname = $new_sname;
        $snaming = 1;
        $schanged = 1;
        next;
    }
}

&flush_hit($outf) if ($expect<=0.001);
print STDERR "OK, processed $n_queries queries, $n_hits hits\n";
close(BR);
close($outf);


sub isEuk {
  my ($q,$str,$pi)=@_;
  return '' if ($pi<40);
  my @a=split(/\[/,$str);
  foreach my $ag (@a) {
    next if ($ag!~/\]/);
    my @b=split(/\]/,$ag);
    next if ($b[0] eq 'synthetic construct');
    if ($b[0]=~/ / && $euks=~/$b[0]/ && $proks!~/$b[0]/) { 
      $q=~/(\S+).*$/; my $c=$1;
      print "FOund euk hit $b[0] to $c\n";
      #$c=~/^(.+)_\d+$/; $c=$1;
      #print "Returning $c\n";
      return $c;
    }
  }
  return '';
}

sub flush_hit
{
    my $fh=$_[0];
    return if ($euk);
    $qhits->{$qname}=0 unless exists $qhits->{$qname};
    
    if (!$hchanged) { return; }
    if ($qstart<0 || $qend<0 || $sstart<0 || $send<0)
    {
        print STDERR "Error: no coordinates!\n";
        $hchanged = 0;
        return;
    }
    if ($bits<0 || $expect eq '' || $length<0 || $ident<0)
    {
        print STDERR "Error: parameters missing!\n";
        $hchanged = 0;
        return;
    }
    if ($frame eq '') { $frame = '-'; }
    if ($positives < 0) { $positives = '-'; }
    if ($gaps < 0) { $gaps = '-'; }
    if ($qchanged)
    {
        $qname =~ s/\s+$//;
        #print "\n$qname ($qlen)\n";
        $qchanged = 0;
        $schanged = 1;
    }
    if ($schanged)
    {
        $sname =~ s/\s{2,}/ /g;
        $sname =~ s/\s+$//;
        $sname =~ s/^\s+//;
        $sname =~ s/^lcl\|//;
        #print "     $sname ($slen)\n";
        $schanged = 0;
    }
    $qhits->{$qname}++;
    if ($qhits->{$qname}>2) {
      return;
    }
    print $fh "$qname\t$sname\t$qlen\t$slen\t$qstart\t$qend\t$sstart\t$send\t$bits\t$ident\t$gaps\t$positives\t$expect\n";
    $hchanged = 0;
    $frame = '';
    $n_hits++;
}
