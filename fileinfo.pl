#!/usr/bin/perl
use CGI qw/:standard -no_xhtml/;
use URI::Escape;
use strict;
use oyster::conf;
use oyster::taginfo;
use oyster::fifocontrol;
use oyster::common;

my %config = oyster::conf->get_config('oyster.conf');

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

print "$fileonly</p>\n";

my $isblacklisted = 0;
open (BLACKLIST, "${config{'savedir'}}blacklist");
while (my $rule = <BLACKLIST>) {
    chomp($rule);
    $isblacklisted = 1 if ($file =~ /$rule/);
}
close (BLACKLIST);

my $escapedfile = uri_escape("$file", "^A-Za-z");

if ($isblacklisted) {
    print "<p class='blacklisted'>File is blacklisted</p>";
} else {
    print "<table width='100%'><tr><td align='left'><a class='file' href='oyster-gui.pl?vote=$escapedfile' target='curplay'>Vote for this song</a></td>\n";
    my $regexpfile = uri_escape("^$file\$", "^A-Za-z");
    print "<td align='right'><a class='file' href='blacklist.pl?affects=${regexpfile}&amp;action=add'>Add this song to Blacklist</td></tr></table>";
}

my %tag = oyster::taginfo->get_tag("$mediadir$file");

print "<table cellpadding='10'>";
print "<tr><td><strong>Title</strong></td><td>$tag{'title'}</td></tr>";
print "<tr><td><strong>Artist</strong></td><td>$tag{'artist'}</td></tr>";
print "<tr><td><strong>Album</strong></td><td>$tag{'album'}</td></tr>";
print "<tr><td><strong>Track Number</strong></td><td>$tag{'track'}</td></tr>";
print "<tr><td><strong>Year</strong></td><td>$tag{'year'}</td></tr>";
print "<tr><td><strong>Genre</strong></td><td>$tag{'genre'}</td></tr>";
print "<tr><td><strong>File Format</strong></td><td>$tag{'format'}</td></tr>";
print "<tr><td colspan='2'>&nbsp;</td></tr>";
print "<tr><td><strong>Current Oyster-Score</strong></td>";
print "<td><a href='fileinfo.pl?action=scoredown&file=$escapedfile'><img src='themes/${config{'theme'}}/scoredownfile.png' border='0' alt='-'></a> ";
print "<strong>$tag{'score'}</strong>";
print " <a href='fileinfo.pl?action=scoreup&file=$escapedfile'><img src='themes/${config{'theme'}}/scoreupfile.png' border='0' alt='+'></a></td></tr>";
print "</table>";

print end_html;
