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

open (LOG, "${config{'savedir'}}logs/$playlist");
my @log = <LOG>;
my @worklog = @log;
close (LOG);

my @lastplayed = ();
my $votedfiles = 0;
my $randomfiles = 0;
my $scoredfiles = 0;
my @mostplayed = get_mostplayed();
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

    my ($playreason, $filename);
    my $line;
    my $check = '';

    foreach $line (@worklog) {
	chomp($line);
	$_ = $line;
	($playreason, $filename) = m@^[0-9]{8}\-[0-9]{6}\ ([^\ ]*)\ (.*)$@;
	if (($playreason ne 'BLACKLIST') && ($check ne '')) {
	    push (@lastplayed, "$check");
	}
	if ($#lastplayed > 9) {
	    shift (@lastplayed);
	}
	$check = '';
	if ($playreason eq 'DONE') {
	    if ($timesplayed{$filename}) {
		$timesplayed{$filename}++;
		$maxplayed++ if ($timesplayed{$filename} > $maxplayed);
	    } else {
		$timesplayed{$filename} = 1;
		$maxplayed = 1 if ($maxplayed == 0);
	    }
	} elsif ($playreason eq 'VOTED') {
            $votedfiles++;
	    $check = "$filename, $playreason";
        } elsif ($playreason eq 'PLAYLIST') {
            $randomfiles++;
	    $check = "$filename, $playreason";
        } elsif ($playreason eq 'SCORED') {
            $scoredfiles++;
	    $check = "$filename, $playreason";
        }

    }

    my $counter = 10;
    while (($maxplayed > 0) && ($counter > 0)) {
	foreach my $filename (keys %timesplayed) {
	    if (($timesplayed{$filename} == $maxplayed) && ($counter > 0)) {
		push (@mostplayed, "${filename}, $timesplayed{$filename}");
		$counter--;
	    }
	}
	$maxplayed--;
    }

    return @mostplayed;

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
