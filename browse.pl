#!/usr/bin/perl
use CGI qw/:standard -no_xhtml/;
use URI::Escape;
use strict;
use oyster::conf;
use oyster::common;

my %config = oyster::conf->get_config('oyster.conf');

oyster::common->navigation_header();

my $mediadir = $config{'mediadir'};
my $givendir = '/';

if (param('dir')) {
    $givendir=param('dir') . "/";
    $givendir =~ s@//$@/@;
    $givendir =~ s/\.\.\///g;
    $givendir = '/' if ($givendir eq "..");
}

my $oysterruns = 0;

if (-e $config{'basedir'}) {
    $oysterruns = 1;
}

if ((!($givendir eq '/')) && (-e "$mediadir$givendir")) {

    print "<p><strong>Current directory: ";

    my @dirs = split(/\//, $givendir);
    my $incdir = '';
    foreach my $partdir (@dirs) {
	my $escapeddir = uri_escape("$incdir$partdir", "^A-Za-z");
	my $escapedpartdir = $partdir;
	$escapedpartdir =~ s/&/&amp;/g;
	print "<a href='browse.pl?dir=$escapeddir'>$escapedpartdir</a> / ";
	$incdir = $incdir . "$partdir/";
    }

    print "</strong></p>";

    my $topdir = $givendir;
    $topdir =~ s/\Q$mediadir\E//;
    if ($topdir =~ /^[^\/]*\/$/) {
	$topdir = '';
    } else {
	$topdir =~ s/\/[^\/]*\/$//;
    }

    my $escapeddir = uri_escape($topdir, "^A-Za-z");
    print "<a href='browse.pl?dir=$escapeddir'>One level up</a><br><br>";

} elsif (!(-e "$mediadir$givendir")) {   
    print h1('Error!');
    print "The directory $givendir could not be found.";
    print end_html;
}

my $globdir = "$mediadir$givendir";
$globdir =~ s/\ /\\\ /g;
my @entries = <$globdir*>;

print "<table width='100%'>";

my @files = my @dirs = ();

foreach my $entry (@entries) {
    if (-d "$entry") {
	push (@dirs, "$entry");
    } elsif (-f "$entry") {
	push (@files, "$entry");
    }
}

foreach my $dir (@dirs) {
    $dir =~ s/\Q$mediadir\E//;
    my $escapeddir = uri_escape("$dir", "^A-Za-z");
    $dir =~ s/^.*\///;
    $dir =~ s/&/&amp;/g;
    print "<tr>";
    print "<td><a href='browse.pl?dir=$escapeddir'>$dir</a></td>";
    print "<td></td>";
    print "</tr>\n";
}

my $cssfileclass = 'file2';
my $csslistclass = 'playlist2';

foreach my $file (@files) {
    $file =~ s/\Q$mediadir$givendir\E//;
    print "<tr>";
    if (($file =~ /mp3$/) || ($file =~ /ogg$/)) {
	my $escapeddir = "$givendir$file";
	$escapeddir =~ s/\Q$mediadir\E//;
	$escapeddir = uri_escape("$escapeddir", "^A-Za-z");
	if ($cssfileclass eq 'file') {
	    $cssfileclass = 'file2';
	} else {
	    $cssfileclass = 'file';
	}
	my $escapedfile = $file;
	$escapedfile =~ s/&/&amp;/g;
	print "<td><a class='$cssfileclass' href='fileinfo.pl?file=$escapeddir'>$escapedfile</a></td>";
	if ($oysterruns) {
	    print "<td><a class='$cssfileclass' href='oyster-gui.pl?vote=$escapeddir' target='curplay'>Vote</a></td>";
	} else {
	    print "<td></td>";
	}
    } elsif(($file =~ /m3u$/) || ($file =~ /pls$/)) {
	my $escapeddir = "$givendir$file";
	$escapeddir =~ s/\Q$mediadir\E//;
	$escapeddir = uri_escape("$escapeddir", "^A-Za-z");
	if ($csslistclass eq 'playlist') {
	    $csslistclass = 'playlist2';
	} else {
	    $csslistclass = 'playlist';
	}
	my $escapedfile = $file;
	$escapedfile =~ s/&/&amp;/g;
	print "<td><a class='$csslistclass' href='viewlist.pl?list=$escapeddir'>$escapedfile</a></td>";
	if ($oysterruns) {
	    print "<td><a class='$csslistclass' href='oyster-gui.pl?votelist=$escapeddir' target='curplay'>Vote</a></td>";
	} else {
	    print "<td></td>";
	}
    } else {
	print "<td>$file</td>";
	print "<td></td>";
    }
    print "</tr>\n";
}

print "</table>";
print end_html;
