#!/usr/bin/perl
# oyster - a perl-based jukebox and web-frontend
#
# Copyright (C) 2004 Benjamin Hanzelmann <ben@nabcos.de>,
#  Stephan Windmüller <windy@white-hawk.de>,
#  Stefan Naujokat <git@ethric.de>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

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

print oyster::common->remove_html($fileonly) . "</p><br clear='all'>\n";

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
    print "<td align='right'><a class='file' href='blacklist.pl?affects=${regexpfile}&amp;action=add'>Add this song to Blacklist</a></td></tr></table>";
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
my $coverdata = oyster::common->get_cover($albumdir, $config{'coverwidth'});

print "<table border='0' width='100%'>";
if ($tag{'title'}) {
    print "<tr><td class='fileinfo'><strong>Title</strong></td><td>$tag{'title'}</td><td rowspan='6' class='fileinfoimage' width='120'>$coverdata</td></tr>";
} else {
    print "<tr><td class='fileinfo'></td><td rowspan='6'>$coverdata</td></tr>";
}
print "<tr><td class='fileinfo'><strong>Artist</strong></td><td>$tag{'artist'}</td></tr>" if ($tag{'artist'});
print "<tr><td class='fileinfo'><strong>Album</strong></td><td>$tag{'album'}</td></tr>" if ($tag{'album'});
print "<tr><td class='fileinfo'><strong>Track Number</strong></td><td>$tag{'track'}</td></tr>" if ($tag{'track'});
print "<tr><td class='fileinfo'><strong>Year</strong></td><td>$tag{'year'}</td></tr>" if ($tag{'year'});
print "<tr><td class='fileinfo'><strong>Genre</strong></td><td>$tag{'genre'}</td></tr>" if ($tag{'genre'});
print "<tr><td class='fileinfo'><strong>Comment</strong></td><td>$tag{'comment'}</td></tr>" if ($tag{'comment'});
print "<tr><td class='fileinfo'><strong>File Format</strong></td><td>$tag{'format'}</td></tr>";
print "<tr><td class='fileinfo'><strong>Playtime</strong></td><td>$tag{'playtime'}</td></tr>" if ($tag{'playtime'});
print "<tr><td colspan='2'>&nbsp;</td></tr>";
print "<tr><td class='fileinfo'><strong>Times played</strong></td><td>$timesplayed</td></tr>";
print "<tr><td class='fileinfo'><strong>Current Oyster-Score</strong></td>";
print "<td><a href='fileinfo.pl?action=scoredown&amp;file=$escapedfile'><img src='themes/${config{'theme'}}/scoredownfile.png' border='0' alt='-'></a> ";
print "<strong>$tag{'score'}</strong>";
print " <a href='fileinfo.pl?action=scoreup&amp;file=$escapedfile'><img src='themes/${config{'theme'}}/scoreupfile.png' border='0' alt='+'></a></td></tr>";
print "</table>";

print end_html;
