#!/usr/bin/perl
use CGI qw/:standard -no_xhtml/;
use URI::Escape;
use strict;
use oyster::conf;
use oyster::taginfo;

my %config = oyster::conf->get_config('oyster.conf');

print
    header,
    start_html(-title=>'Oyster-GUI',
	       -style=>{'src'=>"themes/${config{'theme'}}/layout.css"},
	       -head=>CGI::meta({-http_equiv => 'Content-Type',
				 -content    => 'text/html; charset=iso-8859-1'}));

print "<table width='100%'><tr>";
print "<td align='center' width='20%'><a href='browse.pl'>Browse</a></td>";
print "<td align='center' width='20%'><a href='search.pl'>Search</a></td>";
print "<td align='center' width='20%'><a href='blacklist.pl'>Blacklist</a></td>";
print "<td align='center' width='20%'><a href='score.pl'>Scoring</a></td>";
print "<td align='center' width='20%'><a href='statistics.pl'>Statistics</a></td>";
print "</tr></table>";
print "<hr>";

my %config = oyster::conf->get_config('oyster.conf');

my @mostplayed = get_mostplayed();

print h1('Most played songs');

my $cssclass = 'file2';

print "<table width='100%'>";
print "<tr><th align='left'>Song</th><th>Times played</th></tr>";
foreach my $line (@mostplayed) {
    $line =~ /(.*)\,\ ([0-9]*)$/;
    my $filename = $1;
    my $timesplayed = $2;
    my $displayname = oyster::taginfo->get_tag_light($filename);
    $filename =~ s/^\Q$config{'mediadir'}\E//;
    my $escapedfilename = uri_escape("$filename", "^A-Za-z");

    if ($cssclass eq 'file') {
	$cssclass = 'file2';
    } else {
	$cssclass = 'file';
    }

    print "<tr><td><a class='$cssclass' href='fileinfo.pl?file=/$escapedfilename'>$displayname</a></td>";
    print "<td class='$cssclass' align='center'>$timesplayed</td></tr>\n";
}
print "</table>";

my @lastplayed = get_lastplayed();

print h1('Recently played songs');

my $cssclass = 'file2';

print "<table width='100%'>";
print "<tr><th align='left'>Song</th><th>Playreason</th></tr>";


foreach my $line (@lastplayed) {
    $line =~ /(.*)\,\ ([A-Z]*)$/;
    my $filename = $1;
    my $playreason = $2;
    my $displayname = oyster::taginfo->get_tag_light($filename);
    $filename =~ s/^\Q$config{'mediadir'}\E//;
    my $escapedfilename = uri_escape("$filename", "^A-Za-z");

    if ($cssclass eq 'file') {
	$cssclass = 'file2';
    } else {
	$cssclass = 'file';
    }

    print "<tr><td><a class='$cssclass' href='fileinfo.pl?file=/$escapedfilename'>$displayname</a></td>";
    print "<td class='$cssclass' align='center'>$playreason</td></tr>\n";


}

exit 0;













open (LOG, "${config{'savedir'}}log");

my $next = '';
my $cssclass = 'file2';

print "<table>";

while ((!($next eq '')) || (my $line = <LOG>)) {
    if (!($next eq '')) {
	$line = $next;
	$next = '';
    }
    my ($year, $month, $day, $hour, $minute, $second, $playreason, $filename);
    chomp($line);
    $_ = $line;
    ($year, $month, $day, $hour, $minute, $second, $playreason, $filename) =
	m@^([0-9]{4})([0-9]{2})([0-9]{2})\-([0-9]{2})([0-9]{2})([0-9]{2})\ ([^\ ]*)\ (.*)$@;
    if (($playreason eq 'PLAYLIST') || ($playreason eq 'LASTVOTES') || ($playreason eq 'VOTED')) {
	do {
	    $line = <LOG>;
	} while ($line =~ /^[0-9]{8}\-[0-9]{6}\ [UN]{0,2}PAUSED\ /);
	chomp($line);
	$_ = $line;
	my ($endreason, $filename2) = '';
	($endreason, $filename2) = m@^[0-9]{8}\-[0-9]{6}\ ([^\ ]*)\ (.*)$@;
	my $display = oyster::taginfo->get_tag_light($filename);
	if ($cssclass eq 'file') {
	    $cssclass = 'file2';
	} else {
	    $cssclass = 'file';
	}
	if (!($endreason eq '')) {
	    $endreason = " / $endreason";
	}
	$filename =~ s/^\Q$config{'mediadir'}\E//;
	$filename = "/$filename";
	my $escapedfilename = uri_escape("$filename", "^A-Za-z");
	print "<tr><td>$playreason$endreason</td>";
	print "<td><a class='$cssclass' href='fileinfo.pl?file=$escapedfilename'>$display</a></td></tr>\n";
	if (!($filename eq $filename2)) {
	    $next = $line;
	}
    }
}

print "</table>";
print end_html;

exit 0;

sub get_mostplayed {

    my @mostplayed = ();
    my %timesplayed = ();
    my $maxplayed = 0;

    open (LOG, "${config{'savedir'}}log");
    my @log = <LOG>;
    my @worklog = @log;
    close (LOG);
    foreach my $line (@worklog) {
	my ($year, $month, $day, $hour, $minute, $second, $playreason, $filename);
	chomp($line);
	$_ = $line;
	($year, $month, $day, $hour, $minute, $second, $playreason, $filename) =
	    m@^([0-9]{4})([0-9]{2})([0-9]{2})\-([0-9]{2})([0-9]{2})([0-9]{2})\ ([^\ ]*)\ (.*)$@;
	if (($playreason eq 'PLAYLIST') || ($playreason eq 'LASTVOTES') || ($playreason eq 'VOTED')) {
	    if ($timesplayed{$filename}) {
		$timesplayed{$filename}++;
		$maxplayed++ if ($timesplayed{$filename} > $maxplayed);
	    } else {
		$timesplayed{$filename} = 1;
		$maxplayed = 1 if ($maxplayed == 0);
	    }
	}
    }

    my $counter = 10;
    while (($maxplayed > 0) && ($counter > 0)) {
	foreach my $line (@worklog) {
	    my ($year, $month, $day, $hour, $minute, $second, $playreason, $filename);
	    chomp($line);
	    $_ = $line;
        ($year, $month, $day, $hour, $minute, $second, $playreason, $filename) =
            m@^([0-9]{4})([0-9]{2})([0-9]{2})\-([0-9]{2})([0-9]{2})([0-9]{2})\ ([^\ ]*)\ (.*)$@;
	    if (($playreason eq 'PLAYLIST') || ($playreason eq 'LASTVOTES') || ($playreason eq 'VOTED')) {
		if (($timesplayed{$filename} == $maxplayed) && ($counter > 0)) {
		    push (@mostplayed, "${filename}, $timesplayed{$filename}");
		    $timesplayed{$filename} = 0;
		    $counter--;
		}
	    }
	}
	$maxplayed--;
    }

    return @mostplayed;

}

sub get_lastplayed {

    my @played = ();
    my @lastplayed = ();

    open (LOG, "${config{'savedir'}}log");
    while (my $line = <LOG>) {
	my ($year, $month, $day, $hour, $minute, $second, $playreason, $filename);
	chomp($line);
	$_ = $line;
        ($year, $month, $day, $hour, $minute, $second, $playreason, $filename) =
            m@^([0-9]{4})([0-9]{2})([0-9]{2})\-([0-9]{2})([0-9]{2})([0-9]{2})\ ([^\ ]*)\ (.*)$@;
	if (($playreason eq 'PLAYLIST') || ($playreason eq 'LASTVOTES') || ($playreason eq 'VOTED')) {
	    push (@played, "$filename, $playreason");
	}
    }
    close LOG;

    my $counter = @played - 10;
    my $count = @played;
    #print "played hat $count Eintraege<br>";
    #print "counter ist $counter<br>";
    #print "Naechstes ware $played[$counter]<br>";

    while ($counter < @played) {
	push (@lastplayed, $played[$counter]);
	$counter++;
    }

    return @lastplayed;

}
