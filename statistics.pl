#!/usr/bin/perl
use CGI qw/:standard -no_xhtml/;
use URI::Escape;
use strict;
use oyster::conf;
use oyster::taginfo;
use oyster::common;

oyster::common->navigation_header();

my %config = oyster::conf->get_config('oyster.conf');
my $playlist = oyster::conf->get_playlist();

my @mostplayed = get_mostplayed();
my $votedfiles = get_numfiles('VOTED');
my $randomfiles = get_numfiles('PLAYLIST');
my $scoredfiles = get_numfiles('SCORED');
my $totalfilesplayed = $votedfiles + $randomfiles + $scoredfiles;

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

print "</table>";

print h1('Some numbers');

my $totalfiles = `wc -l  ${config{savedir}}lists/$playlist`;
$totalfiles =~ /^[\ ]*([0-9]*)/;
$totalfiles = $1;

print "<table width='100%'>";
print "<tr><td><strong>Total files in playlist</strong></td><td>$totalfiles</td></tr>";
print "<tr><td><strong>Files blacklisted</strong></td><td>" . get_blacklisted() . "</td></tr>";
print "<tr><td><strong>Total files played</strong></td><td>$totalfilesplayed</td></tr>";
print "<tr><td><strong>Files played because of vote</strong></td><td>$votedfiles</td></tr>";
print "<tr><td><strong>Files played because of scoring</strong></td><td>$scoredfiles</td></tr>";
print "<tr><td><strong>Files played from playlist at random</strong></td><td>$randomfiles</td></tr>";
print "<tr><td><strong>Ratio Scoring/Random (should be ~ $config{'voteplay'})</strong></td>";
print "<td>" . int(($scoredfiles/($scoredfiles+$randomfiles)*100)) . "</td></tr>";
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
	if ($playreason eq 'DONE') {
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
	    if (($playreason eq 'PLAYLIST') || ($playreason eq 'SCORED') || ($playreason eq 'VOTED')) {
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
    my $check = '';

    open (LOG, "${config{'savedir'}}log");
    while (my $line = <LOG>) {
	my ($year, $month, $day, $hour, $minute, $second, $playreason, $filename);
	chomp($line);
	$_ = $line;
        ($year, $month, $day, $hour, $minute, $second, $playreason, $filename) =
            m@^([0-9]{4})([0-9]{2})([0-9]{2})\-([0-9]{2})([0-9]{2})([0-9]{2})\ ([^\ ]*)\ (.*)$@;
	if (($playreason ne 'BLACKLIST') && ($check ne '')) {
	    push (@played, "$check");
	}
	$check = '';
	if (($playreason eq 'PLAYLIST') || ($playreason eq 'SCORED') || ($playreason eq 'VOTED')) {
	    $check = "$filename, $playreason";
	}
    }
    close LOG;

    my $counter = @played - 10;
    if (@played < 10) {
	$counter = 0;
    }

    while ($counter < @played) {
	push (@lastplayed, $played[$counter]);
	$counter++;
    }

    return @lastplayed;

}

sub get_numfiles {

    my $numfiles = 0;
    my $type = $_[0];

    open (LOG, "${config{'savedir'}}log");
    while (my $line = <LOG>) {
        my ($year, $month, $day, $hour, $minute, $second, $playreason, $filename);
        chomp($line);
        $_ = $line;
        ($year, $month, $day, $hour, $minute, $second, $playreason, $filename) =
            m@^([0-9]{4})([0-9]{2})([0-9]{2})\-([0-9]{2})([0-9]{2})([0-9]{2})\ ([^\ ]*)\ (.*)$@;
	$numfiles++ if ($playreason eq $type);
    }
    close LOG;

    return $numfiles;

}

sub get_blacklisted {

    # Counts all files, which are affected by a blacklist-rule

    my $count = 0;
    my @affectlines = ();

    my $mediadir = $config{'mediadir'};
    $mediadir =~ s/\/$//;

    open (BLACKLIST, "${config{savedir}}blacklists/$playlist");
    while (my $line = <BLACKLIST>) {
	chomp($line);
	push (@affectlines, $line);
    }
    close (BLACKLIST);

    open (LIST, "${config{savedir}}lists/$playlist");

    while (my $line = <LIST>) {
	my $isaffected = 0;
	chomp($line);
	$line =~ s/^\Q$mediadir\E//;
	foreach my $affects (@affectlines) {
	    $isaffected = 1 if ($line =~ /$affects/i);
	}
	$count++ if ($isaffected);
    }
    close (LIST);

    return $count;
    
}
