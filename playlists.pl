#!/usr/bin/perl
# oyster - a perl-based jukebox and web-frontend
#
# Copyright (C) 2004 Benjamin Hanzelmann <ben@nabcos.de>, Stepan Windmüller <windy@white-hawk.de>, Stefan Naujokat <git@ethric.de>
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

oyster::common->navigation_header();

if (param('action') && (param('listname') || param('newlistname'))) {
    my $file = param('listname') || param('newlistname');
    oyster::fifocontrol->do_action(param('action'), $file, '');
}

my $globdir = "${savedir}lists/";
my @entries = <$globdir*>;

my @files = ();

foreach my $entry (@entries) {
    if (-f "$entry") {
	$entry =~ s/$globdir//;
	push (@files, "$entry");
    }
}

my $playlist = oyster::conf->get_playlist();

print "<table width='100%' style='margin-bottom: 2em;'>";

foreach my $file (@files) {
    if ($file eq $playlist) {
	print "<tr><td><i>$file</i></td><td>currently playing</td>";
	print "<td></td><td></td>";
    }
    else {
	print "<tr><td>$file</td>" .
	    "<td><a href='playlists.pl?action=loadlist&amp;listname=$file'>" .
	    "Load List</a></td>";
	print "<td><a href='editplaylist.pl?action=edit&amp;" .
	    "playlist=$file'>Edit List</a></td>\n";
	print "<td><a href='playlists.pl?action=delete&amp;" .
	    "listname=$file'>Delete List</a></td>\n";

    }

}

print "</tr></table>";

print start_form;

print hidden(-name=>'action', -default=>'addnewlist');

print textfield(-name=>'newlistname',-default=>'');
print submit(-value=>'Create new list',-style=>'margin-left: 2em;');

print end_form;


print end_html;
