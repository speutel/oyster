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
use oyster::common;

my %config = oyster::conf->get_config('oyster.conf');

my $frames = 1;
my $framestr = '';
my $framestr2 = '';

if ((param('frames') && (param('frames') eq 'no'))) {
	$frames = 0;
	$framestr = '?frames=no';
	$framestr2 = '&amp;frames=no';
}

if ($frames) {
	oyster::common->navigation_header();
} else {
	oyster::common->noframe_navigation();
	print h1('Browse');
}

my $mediadir = $config{'mediadir'};
$mediadir =~ s/\/$//;
my $givendir = '/';

if (param('dir')) {
	# Check given parameter for possible security risks
	$givendir=param('dir') . "/";
	$givendir =~ s@//$@/@;
	$givendir =~ s/\.\.\///g;
	$givendir = '/' if ($givendir eq "..");
}

# Is oyster currently running?

my $oysterruns = 0;

if (-e $config{'basedir'}) {
	$oysterruns = 1;
}

# Give an option to browse all files or only the playlist

my $playlist = oyster::conf->get_playlist();

if (param('playlist')) {
	print "<p align='right'><a class='file' href='browse.pl" .
	"?dir=" . param('dir') . "${framestr2}'>Browse all files</a></p>";
} elsif ($playlist ne 'default' ) {
	print "<p align='right'><a class='file' href='browse.pl?playlist=" .
	$playlist . "${framestr2}'>Browse in current playlist</a></p>";
}

if (($givendir ne '/') && (-e "$mediadir$givendir")) {

	print "<p>" . oyster::common->get_cover($mediadir . $givendir, "100");

	# split path along "/", create link for every part

	print "<strong>Current directory: ";

	my @dirs = split(/\//, $givendir);
	my $incdir = '';
	foreach my $partdir (@dirs) {
		my $escapeddir = uri_escape("$incdir$partdir", "^A-Za-z");
		my $escapedpartdir = oyster::common->remove_html($partdir);
		if (param('playlist')) {
			print "<a href='browse.pl?dir=$escapeddir&playlist=" .
			param('playlist') . "${framestr2}'>$escapedpartdir</a> / ";
		} else {
			print "<a href='browse.pl?dir=${escapeddir}${framestr2}'>$escapedpartdir</a> / ";
		}
		$incdir = $incdir . "$partdir/";
	}

	print "</strong></p><br clear='all'>";

	# Get the parent directory

	my $parentdir = $givendir;
	$parentdir =~ s/\Q$mediadir\E//;
	if ($parentdir =~ /^[^\/]*\/$/) {
		$parentdir = '';
	} else {
		$parentdir =~ s/\/[^\/]*\/$//;
	}

	# Create a link to the parent directory

	$parentdir = uri_escape($parentdir, "^A-Za-z");
	if (param('playlist')) {
		print "<a href='browse.pl?dir=$parentdir&playlist=" .
		param('playlist') . "${framestr2}'>One level up</a><br><br>";
	} else {
		print "<a href='browse.pl?dir=${parentdir}${framestr2}'>One level up</a><br><br>";
	}

} elsif (!(-e "$mediadir$givendir")) { # if $mediadir == "/": just build filelist, no dir-splitting needed  
	print h1('Error!');
	print "The directory $givendir could not be found.";
	print end_html;
}

my @entries = (); # All files and directories which should be displayed

if (param('playlist')) {

	# Browse playlist

	my $playlist = param('playlist');
	$playlist =~ s@//$@/@;
	$playlist =~ s/\.\.\///g;
	$playlist = '' if ($playlist eq "..");

	my %dirs = (); # All directories in a hash to prevent doubles

	# Collect all matching files and directories

	open (PLAYLIST, "$config{'savedir'}lists/$playlist");
	while (my $line = <PLAYLIST>) {
		if ($line =~ /^\Q$mediadir$givendir\E[^\/]*$/) {
			chomp($line);
			push (@entries, $line);
		}
		if ($line =~ /^(\Q$mediadir$givendir\E[^\/]*)\//) {
			$dirs{$1} = 1;
		}
	}
	close (PLAYLIST);

	# Add all directories to @entries

	foreach my $key (sort (keys %dirs)) {
		push (@entries, $key);
	}
} else {

	# Browse all files

	my $globdir = "$mediadir$givendir";

	# Escape whitespaces and apostrophe
	$globdir =~ s/\ /\\\ /g;
	$globdir =~ s/\'/\\\'/g;
	@entries = <$globdir*>;
}

print "<table width='100%'>";

my (@files, @dirs) = ();

# If files and directories exist, add them to @files and @dirs

foreach my $entry (@entries) {
	if (-d $entry) {
		push (@dirs, $entry);
	} elsif (-f $entry) {
		push (@files, $entry);
	}
}

@dirs = sort (@dirs);
@files = sort (@files);

# First, display all directories

foreach my $dir (@dirs) {
	$dir =~ s/\Q$mediadir\E//;
	my $escapeddir = uri_escape("$dir", "^A-Za-z");
	$dir =~ s/^.*\///;
	$dir =~ s/&/&amp;/g;
	$dir =~ s/</&lt;/g;
	$dir =~ s/>/&gt;/g;    
	print "<tr>";
	if (param('playlist')) {
		print "<td><a href='browse.pl?dir=$escapeddir&playlist=" .
		param('playlist') . "${framestr2}'>$dir</a></td>";
	} else {
		print "<td><a href='browse.pl?dir=${escapeddir}${framestr2}'>$dir</a></td>";
	}
	print "<td></td>";
	print "</tr>\n";
}

# Now display all files

my $cssfileclass = 'file2';
my $csslistclass = 'playlist2';

foreach my $file (@files) {
	$file =~ s/\Q$mediadir$givendir\E//;
	print "<tr>";
	if (($file =~ /mp3$/i) || ($file =~ /ogg$/i)) { # if we have music ...
		my $escapeddir = "$givendir$file";
		$escapeddir =~ s/\Q$mediadir\E//;
		$escapeddir = uri_escape("$escapeddir", "^A-Za-z");

		# alternate colors
		if ($cssfileclass eq 'file') {
			$cssfileclass = 'file2';
		} else {
			$cssfileclass = 'file';
		}
		my $escapedfile = oyster::common->remove_html($file);

		print "<td><a class='$cssfileclass' href='fileinfo.pl?file=${escapeddir}${framestr2}'>$escapedfile</a></td>";

		# only generate "Vote"-link if oyster is running
		if ($oysterruns) {
			print "<td><a class='$cssfileclass' href='oyster-gui.pl?vote=${escapeddir}${framestr2}' target='curplay'>Vote</a></td>";
		} else {
			print "<td></td>";
		}
	} elsif(($file =~ /m3u$/) || ($file =~ /pls$/)) { # if we have a list...
		my $escapeddir = "$givendir$file";
		$escapeddir =~ s/\Q$mediadir\E//;
		$escapeddir = uri_escape("$escapeddir", "^A-Za-z");

		# alternate colors
		if ($csslistclass eq 'playlist') {
			$csslistclass = 'playlist2';
		} else {
			$csslistclass = 'playlist';
		}
		my $escapedfile = oyster::common->remove_html($file);
		print "<td><a class='$csslistclass' href='viewlist.pl?list=${escapeddir}${framestr2}'>$escapedfile</a></td>";

		#only generate "Vote"-Link if oyster is running
		if ($oysterruns) {
			print "<td><a class='$csslistclass' href='oyster-gui.pl?votelist=$escapeddir' target='curplay'>Vote</a></td>";
		} else {
			print "<td></td>";
		}
	} else { # some other kind of file
		my $iscover = 0;
		my @coverfiles = split(/,/, $config{'coverfilenames'});
		foreach my $cover (@coverfiles) {
			$cover =~ s/^.*\.//;
			if ($file =~ /\Q$cover\E$/) {
				$iscover = 1;
			}
		}

		# if we can do nothing - just print it.
		if ($iscover == 0) {
			print "<td>$file</td>";
			print "<td></td>";
		}
	}
	print "</tr>\n";
}

print "</table>";
print end_html;
