#!/usr/bin/perl
use CGI qw/:standard -no_xhtml/;
use URI::Escape;
use strict;
use oyster::conf;
use oyster::taginfo;
use oyster::fifocontrol;
use oyster::common;

my %config = oyster::conf->get_config('oyster.conf');
my $playlist = oyster::conf->get_playlist();

oyster::common->navigation_header();

my $mediadir = $config{'mediadir'};
$mediadir =~ s/\/$//;
my $file = param('file') || '';

if (param('action')) {
    oyster::fifocontrol->do_action(param('action'), $file, '');
}   

if (!(-e "$mediadir$file")) {
    print h1('Error!');
    print "<p>File <strong>$file</strong> could not be found.</p>";
    print end_html;
    exit 0;
}

my $oysterruns = 0;

if (-e $config{'basedir'}) {
    $oysterruns = 1;
}

print "<p>Info for ";

my $subdir = my $fileonly = $file;
$subdir =~ s/^\Q$mediadir\E//;
$subdir =~ s/\/[^\/]*$//;
$fileonly =~ s/^.*\///;
my @dirs = split(/\//, $subdir);
my $incdir = '';
foreach my $partdir (@dirs) {
    my $escapeddir = uri_escape("$incdir$partdir", "^A-Za-z");
    print "<a href='browse.pl?dir=$escapeddir'>$partdir</a> / ";
    $incdir = $incdir . "$partdir/";
}

print "$fileonly</p><br clear='all'>\n";

my $isblacklisted = 0;
my $playlist = oyster::conf->get_playlist();
open (BLACKLIST, "${config{'savedir'}}blacklists/$playlist");
while (my $rule = <BLACKLIST>) {
    chomp($rule);
    $isblacklisted = 1 if ($file =~ /$rule/);
}
close (BLACKLIST);

my $escapedfile = uri_escape("$file", "^A-Za-z");

print "<table width='100%'><tr>";
if ($oysterruns) {
    print "<td align='left'><a class='file' href='oyster-gui.pl?vote=$escapedfile' target='curplay'>Vote for this song</a></td>\n";
} else {
    print "<td></td>\n";
}
my $regexpfile = uri_escape("^$file\$", "^A-Za-z");

if ($isblacklisted) {
    print "<td align='right'><span class='blacklisted'>File is blacklisted</span></td></tr></table>";
} else {
    print "<td align='right'><a class='file' href='blacklist.pl?affects=${regexpfile}&amp;action=add'>Add this song to Blacklist</td></tr></table>";
}

my %tag = oyster::taginfo->get_tag("$mediadir$file");

my $timesplayed = 0;
open (LOG, "${config{'savedir'}}logs/$playlist");
while (my $line = <LOG>) {
    my ($year, $month, $day, $hour, $minute, $second, $playreason, $filename);
    chomp($line);
    $_ = $line;
    ($year, $month, $day, $hour, $minute, $second, $playreason, $filename) =
	m@^([0-9]{4})([0-9]{2})([0-9]{2})\-([0-9]{2})([0-9]{2})([0-9]{2})\ ([^\ ]*)\ (.*)$@;
    if ($filename =~ /\Q$file\E/) {
	if ($playreason eq 'DONE') {
	    $timesplayed++;
	}
    }
}
close LOG;

my $albumdir = $mediadir . $file;
$albumdir =~ s/[^\/]*$//;
my $coverdata = oyster::common->get_cover($albumdir);

print "<table cellpadding='10'>";
if ($tag{'title'}) {
    print "<tr><td><strong>Title</strong></td><td>$tag{'title'}</td><td rowspan='6'>$coverdata</td></tr>";
} else {
    print "<tr><td><strong>Title</strong></td><td>$tag{'title'}</td></tr>";
}
print "<tr><td><strong>Artist</strong></td><td>$tag{'artist'}</td></tr>" if ($tag{'artist'});
print "<tr><td><strong>Album</strong></td><td>$tag{'album'}</td></tr>" if ($tag{'album'});
print "<tr><td><strong>Track Number</strong></td><td>$tag{'track'}</td></tr>" if ($tag{'track'});
print "<tr><td><strong>Year</strong></td><td>$tag{'year'}</td></tr>" if ($tag{'year'});
print "<tr><td><strong>Genre</strong></td><td>$tag{'genre'}</td></tr>" if ($tag{'genre'});
print "<tr><td><strong>Comment</strong></td><td>$tag{'comment'}</td></tr>" if ($tag{'comment'});
print "<tr><td><strong>File Format</strong></td><td>$tag{'format'}</td></tr>";
print "<tr><td><strong>Playtime</strong></td><td>$tag{'playtime'}</td></tr>" if ($tag{'playtime'});
print "<tr><td colspan='2'>&nbsp;</td></tr>";
print "<tr><td><strong>Times played</strong></td><td>$timesplayed</td></tr>";
print "<tr><td><strong>Current Oyster-Score</strong></td>";
print "<td><a href='fileinfo.pl?action=scoredown&file=$escapedfile'><img src='themes/${config{'theme'}}/scoredownfile.png' border='0' alt='-'></a> ";
print "<strong>$tag{'score'}</strong>";
print " <a href='fileinfo.pl?action=scoreup&file=$escapedfile'><img src='themes/${config{'theme'}}/scoreupfile.png' border='0' alt='+'></a></td></tr>";
print "</table>";

print end_html;
