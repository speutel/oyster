#!/usr/bin/perl
# oyster - a perl-based jukebox and web-frontend
#
# Copyright (C) 2004 Benjamin Hanzelmann <ben@nabcos.de>, Stephan Windmüller <windy@white-hawk.de>, Stefan Naujokat <git@ethric.de>
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

oyster::common->navigation_header();

my $mediadir = $config{'mediadir'};
my $givenlist = '';

if (param('list')) {
    $givenlist=param('list');
    $givenlist =~ s@//$@/@;
    $givenlist =~ s/\.\.\///g;
    $givenlist = '' if ($givenlist eq "..");
}

if (($givenlist ne '') && (-e "$mediadir$givenlist")) {

    print "<p><strong>Current directory: ";

    my @dirs = split(/\//, $givenlist);
    my $incdir = '';
    foreach my $partdir (@dirs) {
	my $escapeddir = uri_escape("$incdir$partdir", "^A-Za-z");
	if (($partdir =~ /\.m3u$/) || ($partdir =~ /\.pls$/)) {
	    print "<a class='playlist' href='viewlist.pl?list=$escapeddir'>$partdir</a>";
	} else {
	    print "<a href='browse.pl?dir=$escapeddir'>$partdir</a> / ";
	}
	$incdir = $incdir . "$partdir/";
    }

    print "</strong></p>";

    my $topdir = $givenlist;
    $topdir =~ s/\Q$mediadir\E//;
    $topdir =~ s/\/[^\/]*$//;

    my $escapeddir = uri_escape($topdir, "^A-Za-z");
    print "<a href='browse.pl?dir=$escapeddir'>One level up</a><br><br>";

    print "<table width='100%'>";

    my $cssfileclass = 'file2';

    open(PLAYLIST, "$mediadir$givenlist");
    while (my $line = <PLAYLIST>) {
	chomp($line);
	if ($line =~ /^[^\#]/) {
	    $line =~ s/^\Q$mediadir\E//;
	    $line =~ s/^\.\///;
	    my $escapedfile = uri_escape("$topdir/$line", "^A-Za-z");

	    # $cssclass changes to give each other file                                                                                     
	    # another color                                                                                                                 
            
	    if ($cssfileclass eq 'file') {
		$cssfileclass = 'file2';
	    } else {
		$cssfileclass = 'file';
	    }

	    print "<tr><td><a class='$cssfileclass' href='fileinfo.pl?file=$escapedfile'>$line</a></td>";
	    print "<td><a class='$cssfileclass' href='oyster-gui.pl?vote=$escapedfile' target='curplay'>Vote</a></td></tr>";
	}
    }

    print "</table>";


} else {   
    print h1('Error!');
    print "The playlist $givenlist could not be found.";
    print end_html;
}
