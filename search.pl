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

if ((param('frames') && (param('frames') eq 'no'))) {
	$frames = 0;
	$framestr = '&amp;frames=no';
}

if ($frames) {
	oyster::common->navigation_header();
} else {
	oyster::common->noframe_navigation();
	print h1('Search');
}

my $mediadir = $config{'mediadir'};
$mediadir =~ s/\/$//;
my $search='';
my $searchtype = 'normal';

if (param('searchtype')) {
	if ((param('searchtype') eq 'regex')) {
		$searchtype = 'regex';
	}
}

my $oysterruns = 0;

if (-e $config{'basedir'}) {
	$oysterruns = 1;
}

if (param('search')) {
	$search=param('search');
}

# Create form

my %labels = ('normal' => ' Normal', 'regex' => ' Regular Expression');
my %playlistlabels = ('all' => ' All Songs', 'current' => ' Only current playlist');

print start_form;

my $textfield = textfield(-name=>'search',-default=>'');
my $radiobuttons = radio_group(-name=>'searchtype',-values=>['normal','regex'],-default=>'normal',
	-linebreak=>'true',-labels=>\%labels);
my $playlists = radio_group(-name=>'playlist',-values=>['current','all'],-default=>'current',
	-linebreak=>'true',-labels=>\%playlistlabels);
my $submit = submit(-value=>'Search',-style=>'margin-left: 2em;');

print table({-border=>'0'},
	Tr([
		td([$textfield,$submit]),
		td([$radiobuttons,$playlists])
		])
);

print hidden('frames','no') if (! $frames);

print end_form;

my @results = ();
my $cssclass='file2';

if ($search ne '') {

	# Check in which playlist to search
	my $playlist = 'default';

	if (param('playlist') eq 'current') {
		$playlist = oyster::conf->get_playlist();
	}

	open (LIST, "${config{savedir}}lists/$playlist");
	my @list = <LIST>;

	# Compare filenames with $search and add
	# them to @results

	if ($searchtype eq 'normal') {
		foreach my $line (@list) {
			$line =~ s/\Q$mediadir\E//;
			if ($line =~ /\Q$search\E/i) {
				chomp($line);
				push (@results, $line);
			}
		}
	} elsif ($searchtype eq 'regex') {
		foreach my $line (@list) {
			$line =~ s/\Q$mediadir\E//;
			if ($line =~ /$search/i) {
				chomp($line);
				push (@results, $line);
			}
		}
	}

	# Sort @results alphabetically

	@results = sort @results;
	@results = sort_results('/');

	# List directory in browser

	if (@results > 0) {
		listdir('/',0);
	} else {
		print p('No songs found.');
	}

}

print end_html;

exit 0;

sub listdir {

	# listdir shows files from @results, sorted by directories
	# $basepath is cut away for recursive use

	my $basepath = $_[0];
	my $counter = $_[1];

	while (($counter < @results) && ($results[$counter] =~ /^\Q$basepath\E/)) {
		my $newpath = $results[$counter];
		$newpath =~ s/^\Q$basepath\E//;
		if ($newpath =~ /\//) {

			# $newpath is directory and becomes the top one

			$newpath =~ /^([^\/]*\/)/;
			$newpath = $1;

			# do not add padding for the top level directory

			my $cutnewpath = $newpath;
			$cutnewpath =~ s/\/$//;

			if (!($basepath eq '/')) {
				my $escapeddir = uri_escape("$basepath$cutnewpath", "^A-Za-z");
				print "<div style='padding-left: 1em;'>";
				print strong(a({href=>"browse.pl?dir=${escapeddir}${framestr}"},escapeHTML($cutnewpath)));
				$newpath = "$basepath$newpath";
			}  else {
				my $escapeddir = uri_escape("/$cutnewpath", "^A-Za-z");
				print strong(a({href=>"browse.pl?dir=${escapeddir}${framestr}"},escapeHTML($cutnewpath)));
				$newpath = "/$newpath";
			}

			# Call listdir recursive, then quit padding with <div>

			$counter = listdir($newpath,$counter);
			if (!($basepath eq '/')) {
				print "</div>\n";
			}
		} else {

			# $newpath is a regular file without leading directory

			print "<div style='padding-left: 1em;'>";
			while ($results[$counter] =~ /^\Q$basepath\E/) {

				# Print all filenames in $basedir

				my $filename = $results[$counter];
				$filename =~ s/^.*\///;
				$filename =~ /(.*)\.(...)$/;
				my $nameonly = $1;
				my $escapedfile = uri_escape("$basepath$filename", "^A-Za-z");

				# $cssclass changes to give each other file
				# another color

				if ($cssclass eq 'file') {
					$cssclass = 'file2';
				} else {
					$cssclass = 'file';
				}
				print "<table width='100%'><tr>";
				print "<td align='left'><a href='fileinfo.pl?file=${escapedfile}${framestr}' ";
				print "class='$cssclass'>" . escapeHTML($nameonly) . "</a></td>";
				if ($oysterruns) {
					print "<td align='right'><a href='oyster-gui.pl?vote=${escapedfile}${framestr}' ";
					print "class='$cssclass' target='curplay'>Vote</a></td>";
				} else {
					print "<td></td>";
				}
				print "</tr></table>\n";
				$counter++;
			}
			print "</div>\n";
		}
	}

	return ($counter);

}

sub sort_results {

	# sort_results sorts a directory and its subdirectories by
   # "first dirs, then files"

	my $topdir = $_[0];
	my $skip = ''; # Do not add directories twice
	my (@dirs, @files) = ();

	foreach my $line (@results) {
		if ((($skip ne '') && !($line =~ /^\Q$skip\E/)) || ($skip eq '')) {
			if ($line =~ /^\Q$topdir\E([^\/]*\/)/) {
				# $line is a directory
				$skip = "${topdir}${1}";
				push (@dirs, sort_results($skip));
			} elsif ($line =~ /^\Q$topdir\E[^\/]*$/) {
				# $line is a file
				push (@files, $line);
			}
		}
	}
	
	return(@dirs, @files);

}
