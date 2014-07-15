package TimeFunc;
use Exporter();
@ISA=qw(Exporter);
@EXPORT=qw( _currTime _currTimeArray currDate);
use strict;
use warnings;
use CommonFunc;


sub currDate{
	my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
	my @weekDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
	my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
	my $year = 1900 + $yearOffset;
	$month++;
	if ($second < 10){$second="0".$second;}
	if ($month <10){$month="0".$month;}
	my $theDate = "$year-$month-$dayOfMonth";
	return $theDate;
	
}


sub _currTime
{
my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my @weekDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
my $year = 1900 + $yearOffset;
if ($second < 10){$second="0".$second;}
# if ($month <10){$month="0".$month;}
my $theTime = "$hour:$minute:$second, $weekDays[$dayOfWeek] $months[$month] $dayOfMonth, $year";
return $theTime;

}

#returns the time in an array
sub _currTimeArray
{
my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my @weekDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
my $year = 1900 + $yearOffset;
if ($second < 10){$second="0".$second;}
# if ($month <10){$month="0".$month;}
my @theTime = ($hour,$minute,$second, $weekDays[$dayOfWeek], $months[$month], $dayOfMonth, $year);
return @theTime;

}


1;