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
use oyster::common;

my $frames = 1;
my $framestr = '';

if ((param('frames') && (param('frames') eq 'no'))) {
    $frames = 0;
    $framestr = '&amp;frames=no';
}

if ($frames) {
    oyster::common->navigation_header();
  } else {
      oyster::common->noframe_navigation();
      print h1('Statistics');
  }

my %config = oyster::conf->get_config('oyster.conf');
my $playlist = oyster::conf->get_playlist();

# Load logfile into permanent array

open (LOG, "${config{'savedir'}}logs/$playlist");
my @log = <LOG>;
my @worklog = @log;
close (LOG);

my (
    @lastplayed, # The last 10 played songs
    @mostplayed, # The "Top 10"
    %timesplayed # Stores, how often a file has been played
    ) = ();

my (
    $votedfiles,  # Number of files played because of voting
    $randomfiles, # Number of files played at random
    $scoredfiles, # Number of files played because of scoring
    ) = 0;

my $check = ''; # Check, if a file was blacklisted before counting it

foreach (@worklog) {
    chomp($_);
    (my $playreason, my $filename) = m@^[0-9]{8}\-[0-9]{6}\ ([^\ ]*)\ (.*)$@;

    # second turn: if file is checked and not blacklisted,
    # add it to the last played files.
    if (($playreason ne 'BLACKLIST') && ($check ne '')) {
	push (@lastplayed, "$check");
    }

    # never more than 10 entries
    if ($#lastplayed > 9) {
	shift (@lastplayed);
    }

    # add files to the appropriate counters
    $check = '';
    if ($playreason eq 'DONE') {
	if ($timesplayed{$filename}) {
	    $timesplayed{$filename}++;
	} else {
	    $timesplayed{$filename} = 1;
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

# Get the maximum value for $maxplayed


my $maxplayed = 0;   # How often the Top-1-Song has been played

foreach my $filename (keys %timesplayed) {
    $maxplayed = $timesplayed{$filename} if $timesplayed{$filename} > $maxplayed;
}

# Put the Top-10-Songs in @mostplayed
# inefficient ... someone got a better idea? :)
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

my $totalfilesplayed = $votedfiles + $randomfiles + $scoredfiles;

# Print the collected data

print h1('Most played songs');

print_songs("Times played", @mostplayed);

# Recently played songs

print h1('Recently played songs');

print_songs("Playreason", @lastplayed);

# Some numbers

print h1('Some numbers');

# FIXME perl function for wc?
my $totalfiles = `wc -l  "${config{savedir}}lists/$playlist"`;
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

sub print_songs {

    my $header = $_[0];
    shift @_;
    my @filearray = @_;
    
    my $cssclass = 'file2';

    print "<table width='100%'>";
    print "<tr><th align='left'>Song</th><th>$header</th></tr>";

    # for every song in mostplayed
    #  print artist/title
    foreach my $line (@filearray) {
	$line =~ /(.*)\,\ ([A-Z0-9]*)$/;
	my $filename = $1;
	my $reason = $2;
	my $displayname = oyster::taginfo->get_tag_light($filename);
	$filename =~ s/^\Q$config{'mediadir'}\E//;  # remove mediadir from filename
	# (does not turn up in oyster-gui)
	my $escapedfilename = uri_escape("$filename", "^A-Za-z");

	# switch colors
	if ($cssclass eq 'file') {
	    $cssclass = 'file2';
	} else {
	    $cssclass = 'file';
	}

	print "<tr><td><a class='$cssclass' href='fileinfo.pl?file=/${escapedfilename}${framestr}'>$displayname</a></td>";
	print "<td class='$cssclass' align='center'>$reason</td></tr>\n";
    }
    print "</table>";
}
