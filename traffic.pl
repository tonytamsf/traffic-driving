#!/usr/bin/perl -w

use strict;

my $S_freeway = shift;
unless($S_freeway)
{
    print "Usage: traffic.pl [880N|880S|101N|101S|80E...]\n";
    die;
}
$S_freeway =~ s/E\b/East/i;
$S_freeway =~ s/W\b/West/i;
$S_freeway =~ s/N\b/North/i;
$S_freeway =~ s/S\b/South/i;
$S_freeway =~ s/(\d)(N|S|E|W)/$1 $2/;
$S_freeway =~ s/\s+/ /;
$S_freeway =~ s/^\s+//;
$S_freeway =~ s/\s+$//;

my $S_url = 'http://www.sigalert.com/speeds.asp?Region=Bay+Area&Road='.$S_freeway;

use LWP::Simple;
use LWP::UserAgent;
use HTTP::Request::Common;
use HTTP::Response;

sub fetch_url
{
    my $S_url = shift; 
    my $OR_UA          = LWP::UserAgent->new();
    $OR_UA->timeout(5);
    my $OR_request     = GET($S_url);
    my $S_get_html     = undef;
    my $OR_response    = $OR_UA->request($OR_request);
    
    if  ($OR_response->is_success()) {
	return $OR_response->content();
    }
    return undef;
}

sub get_traffic_info
{
    my $S_url = shift;
    print "fetching $S_url\n";
    my $S_html = fetch_url($S_url);
    unless (defined($S_html))
    {
	return undef;
    }
    #print($S_html);
    #while ($S_html =~ s/DrawSpeed.*?(\d+),\'(\w+)\',(\w+),[^,+],[^,]+,'([^']+)'//)
    my @A_slow_downs = ();
    my @A_all_speeds = ();
    my @A_accident   = ();
    my $S_all_speed  = 0;
    my $S_num_points = 0;
    
    while (1)
    {
	# DrawSpeed(61,'ffffff',false,-1,'ffffff','Dore Ave',2);
	if ($S_html =~ s/DrawSpeed.*?(\d+),\'(\w+)\',(\w+),[^,]+,[^,]+,'([^\']+)'//)
	{
	    my ($S_speed, $S_color, $S_place) = ($1,$2,$4);
	    if ($S_color ne 'ffffff')
	    {
		print "$S_speed MPH", " $S_place","\n";
		push(@A_slow_downs, "$S_speed MPH"." $S_place");
	    }
	    $S_num_points++;
	    $S_all_speed += $S_speed;
	    push(@A_all_speeds, "$S_speed MPH"." $S_place");
	    
	} elsif ($S_html =~ s/DrawIncident\((\d+),'([^\']+)','([^\']+)','([^\']+)','([^\']+)'//)
	{
	    #DrawIncident(1340031381,'Disabled Vehicle','101 North at Sfo','2:42 PM','ffff00');
	    
	    #push(@A_accident, "$2 $3 $4");
	    print "$2 $3 $4\n";
	} else {
	    last;
	}
    }
    if (@A_all_speeds&& $S_num_points)
    {
	printf("AVG %2.2f MPH\n", $S_all_speed/$S_num_points);
    }
    if (@A_accident)
    {
	print join("\n", @A_accident),"\n";
    }
    if (@A_slow_downs)
    {
	print "** Slow downs\n";
	print join("\n", @A_slow_downs),"\n";
    }
}
print "$S_freeway\n";
get_traffic_info($S_url);
