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
use oyster::fifocontrol;

my %config = oyster::conf->get_config('oyster.conf');
my $savedir = $config{'savedir'};

my $frames = 1;
my $framestr = '';

if ((param('frames') && (param('frames') eq 'no'))) {
	$frames = 0;
	$framestr = '&amp;frames=no';
}

my $oysterruns = 0;

if (-e $config{'basedir'}) {
	$oysterruns = 1;
}

if ($frames) {
	oyster::common->navigation_header();
} else {
	oyster::common->noframe_navigation();
	print h1('Playlists');
}

if (param('action') && (param('listname') || param('newlistname'))) {
	if (param('action') eq 'confirmdelete') {
		confirmdelete();
		exit 0;
	} else {
		my $file = param('listname') || param('newlistname');
		oyster::fifocontrol->do_action(param('action'), $file, '');
	}
}

my $globdir = "${savedir}lists/";
my @entries = <$globdir*>;

my @files = ();
my %section = ();

foreach my $entry (@entries) {
	if (-f "$entry") {
		$entry =~ s/$globdir//;
		push (@files, "$entry");
		if ($entry =~ /_/) {
			$entry =~ s/_.*//;
			$section{$entry} = 1;
		}
	}
}

my $playlist = "";

if ((param('action') eq 'loadlist') && param('listname')) {
	$playlist = param('listname');
} else {
	$playlist = oyster::conf->get_playlist();
}

print "<table width='100%' style='margin-bottom: 2em;'>";

print "<tr><td colspan='5'>" . h2('Default') . "</td></tr>";

# Print playlists without a section

if ($playlist eq 'default') {
	print "<tr style='height:3em;'><td><i>default (All songs)</i></td><td class='playlists' colspan='4'><strong>currently playing</strong></td>";
	print "</tr>";
} else {
	print "<tr style='height:3em;'><td>default (All songs)</td>" .
		"<td class='playlists'>";
	if ($oysterruns) {
		print "<a href='playlists.pl?action=loadlist&amp;" .
			"listname=default${framestr}'>Load</a>";
	}
	print "</td><td></td><td></td><td></td></tr>";
}

foreach my $file (@files) {
	if (!($file =~ /_/)) {
		print_playlist($file);
	}
}

# Print all sections

foreach my $section (sort keys(%section)) {
	print "<tr><td colspan='5'>". h2($section) . "</td></tr>";
	foreach my $file(@files) {
		if ($file =~ /^\Q${section}_\E/) {
			print_playlist($file);
		}
	}
}

print "</table>";

print start_form;

print "<input type='hidden' name='action' value='addnewlist'>";

print textfield(-name=>'newlistname',-default=>'');
print submit(-value=>'Create new list',-style=>'margin-left: 2em;');
print hidden('frames','no') if (! $frames);

print end_form;

print end_html;

sub confirmdelete {
	my $playlist = param('listname');
	my $enclist = uri_escape($playlist, "^A-Za-z");
	print h1("Should $playlist be deleted?");
	print a({-href=>"playlists.pl?action=delete&amp;listname=${enclist}${framestr}"},'Yes, delete it');
	print br;
	if ($frames) {
		print a({-href=>"playlists.pl"},'No, return to overview');
	} else {
		print a({-href=>"playlists.pl?frames=no"},'No, return to overview');
	}
	print end_html;
}

sub print_playlist {
	my $file = $_[0];
	my $title = $file;
	$title =~ s/^.*_//;
	my $encfile = uri_escape($file, "^A-Za-z");

	if (($file eq $playlist) && ($file ne 'default')) {
		print "<tr><td><i>$title</i></td><td class='playlists'><strong>currently playing</strong></td>";
		print "<td class='playlists'><a href='editplaylist.pl?action=edit&amp;" .
		"playlist=${encfile}${framestr}'>Edit</a></td><td></td></tr>";
	}
	elsif ($file ne 'default') {
		print "<tr><td>$title</td><td class='playlists'>";
		if ($oysterruns) {
			print "<a href='playlists.pl?action=loadlist&amp;" .
				"listname=${encfile}${framestr}'>Load</a>";
			}
		print	"</td>";
		print "<td class='playlists'><a href='editplaylist.pl?action=edit&amp;" .
		"playlist=${encfile}${framestr}'>Edit</a></td>\n";
		print "<td class='playlists'><a href='editplaylist.pl?action=move&amp;" .
		"playlist=${encfile}${framestr}'>Move/Rename</a></td>\n";
		print "<td class='playlists'><a href='playlists.pl?action=confirmdelete&amp;" .
		"listname=${encfile}${framestr}'>Delete</a></td></tr>\n";

	}
}
