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
use File::Find;

my %config = oyster::conf->get_config('oyster.conf');

oyster::common->navigation_header();

my $action = param('action') || '';
my $playlist = param('playlist') || '';
my @playlist = ();
my $cssclass = 'file2';

if (($action eq 'edit') || ($action eq 'deletefile') || ($action eq 'deletedir')) {
    my $delfile = param('file') || '';
    my $deldir = param('dir') || '';

    print h1(a({href=>"editplaylist.pl?action=edit&playlist=$playlist"},$playlist));
    print a({href=>"editplaylist.pl?action=addbrowse&playlist=$playlist&dir=/"},
	    'Add files to this list...'),br,br;

    # Get all entries from playlist and filter

    open (PLAYLIST, "$config{savedir}lists/$playlist") or die $!;
    while (my $line = <PLAYLIST>) {
	chomp($line);
	$line =~ s/^\Q$config{mediadir}\E/\//;
	if ($action eq 'edit' || (($action eq 'deletefile') && ($line ne $delfile))
	    || (($action eq 'deletedir') && !($line =~ /^\Q$deldir\E\/[^\/]*/))) {
	    push (@playlist, $line);
	}
    }

    @playlist = sort @playlist;

    if (($action eq 'deletefile') || ($action eq 'deletedir')) {

	# Write new playlist

	open (PLAYLIST, ">$config{savedir}lists/$playlist") || error_msg();

	sub error_msg {
	    print strong('Error: Could not save playlist!');
	    print end_html;
	    exit 0;
	}

	foreach my $line (@playlist) {
	    my $printline = $line;
	    $printline =~ s/^\///;
	    $printline = $config{mediadir} . $printline;
	    print PLAYLIST $printline . "\n";
	}
	close PLAYLIST;

    }


    listdir('/',0);

} elsif ($action eq 'addbrowse') {

    browse();

} elsif (($action eq 'adddir') || ($action eq 'addfile')) {
    my %filelist = ();
    my $toadd = param('toadd') || '';


    open (PLAYLIST, "$config{savedir}lists/$playlist") or die $!;
    while (my $line = <PLAYLIST>) {
	$filelist{$line} = 1;
    }

    $toadd =~ s/^\///;

    if ($action eq 'adddir') {
	find( { wanted => \&is_audio_file, no_chdir => 1 },
	      "$config{mediadir}$toadd");

	sub is_audio_file {
	    if ( ($_ =~ /ogg$/i) or ($_ =~ /mp3$/i) ) {
		$filelist{$_ . "\n"} = 1;
	    }
	}
    } elsif ($action eq 'addfile') {
	$filelist{$config{mediadir} . $toadd . "\n"} = 1;
    }
	
    open (FILELIST, ">$config{savedir}lists/$playlist") || error_msg();

	sub error_msg {
	    print strong('Error: Could not save playlist!');
	    print end_html;
	    exit 0;
	}

    foreach my $key (sort (keys %filelist)) {
	print FILELIST $key;
    }
    close(FILELIST);

    browse();

}

sub listdir {

    # listdir shows files from @playlist, sorted by directories
    # $basepath is cut away for recursive use

    my $basepath = $_[0];
    my $counter = $_[1];

    while (($counter < @playlist) && ($playlist[$counter] =~ /^\Q$basepath\E/)) {
	my $newpath = $playlist[$counter];
	$newpath =~ s/^\Q$basepath\E//;
	if ($newpath =~ /\//) {

	    # $newpath is directory and becomes the top one

	    $newpath =~ /^([^\/]*\/)/;
	    $newpath = $1;

	    # do not add padding for the top level directory

	    my $cutnewpath = $newpath;
	    my $escapeddir = '';
	    $cutnewpath =~ s/\/$//;
	    $cutnewpath = escapeHTML($cutnewpath);

	    if (!($basepath eq '/')) {
		print "<div style='padding-left: 1em;'>";
		print "<table width='100%'><tr><td>";
		$escapeddir = uri_escape("$basepath$cutnewpath", "^A-Za-z");
		print b($cutnewpath);
		$newpath = "$basepath$newpath";
	    }  else {
		print "<table width='100%'><tr><td>";
		$escapeddir = uri_escape("/$cutnewpath", "^A-Za-z");
		print b($cutnewpath);
		$newpath = "/$newpath";
	    }
	    print "</td><td align='right'><a href='editplaylist.pl?action=deletedir&" .
		"dir=$escapeddir&playlist=$playlist'>Delete</a></td></tr></table>";

	    # Call listdir recursive, then quit padding with <div>

	    $counter = listdir($newpath,$counter);
	    if (!($basepath eq '/')) {
		print "</div>\n";
	    }
	} else {

	    # $newpath is a regular file without leading directory

	    print "<div style='padding-left: 1em;'>";
	    while ($playlist[$counter] =~ /^\Q$basepath\E/) {

		# Print all filenames in $basedir

		my $filename = $playlist[$counter];
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
		print "<td align='left'><a href='fileinfo.pl?file=$escapedfile'" .
		    "class='$cssclass'>" . escapeHTML($nameonly) . "</a></td>";
		print "<td align='right'><a href='editplaylist.pl?action=deletefile" .
		    "&file=$escapedfile&playlist=$playlist'" .
		    "class='$cssclass'>Delete</a></td>";

		print "</tr></table>\n";
		$counter++;
	    }
	    print "</div>\n";
	}
    }

    return ($counter);

}

sub browse {

    print h1(a({href=>"editplaylist.pl?action=edit&playlist=$playlist"},$playlist));

    my $givendir = '/';

    if (param('dir')) {
	$givendir=param('dir') . "/";
	$givendir =~ s@//$@/@;
	$givendir =~ s/\.\.\///g;
	$givendir = '/' if ($givendir eq "..");
    }

    if ((!($givendir eq '/')) && (-e "$config{mediadir}$givendir")) {

	print "<p><strong>Current directory: ";

	my @dirs = split(/\//, $givendir);
	my $incdir = '';
	foreach my $partdir (@dirs) {
	    my $escapeddir = uri_escape("$incdir$partdir", "^A-Za-z");
	    my $escapedpartdir = $partdir;
	    $escapedpartdir =~ s/&/&amp;/g;
	    print "<a href='editplaylist.pl?action=addbrowse&amp;playlist=$playlist" .
		"&amp;dir=$escapeddir'>$escapedpartdir</a> / ";
	    $incdir = $incdir . "$partdir/";
	}

	print "</strong></p>";

	my $topdir = $givendir;
	$topdir =~ s/\Q$config{mediadir}\E//;
	if ($topdir =~ /^[^\/]*\/$/) {
	    $topdir = '';
	} else {
	    $topdir =~ s/\/[^\/]*\/$//;
	}

	my $escapeddir = uri_escape($topdir, "^A-Za-z");
	print "<a href='editplaylist.pl?action=addbrowse" .
	    "&amp;playlist=$playlist&amp;dir=$escapeddir'>One level up</a><br><br>";
	
    } elsif (!(-e "$config{mediadir}$givendir")) {   
	print h1('Error!');
	print "The directory $givendir could not be found.";
	print end_html;
    }

    my $globdir = "$config{mediadir}$givendir";
    $globdir =~ s/\ /\\\ /g;
    my @entries = <$globdir*>;

    print "<table width='100%'>";
    
    my (@files, @dirs) = ();
    
    foreach my $entry (@entries) {
	if (-d "$entry") {
	    push (@dirs, "$entry");
	} elsif (-f "$entry") {
	    push (@files, "$entry");
	}
    }

    my $cssdirclass = 'dir2';
    my $cssfileclass = 'file2';
    my $csslistclass = 'playlist2';
    my $anchorcounter = 0;

    foreach my $dir (@dirs) {
	if ($cssdirclass eq 'dir') {
	    $cssdirclass = 'dir2';
	} else {
	    $cssdirclass = 'dir';
	}

	$dir =~ s/\Q$config{mediadir}\E//;
	my $escapeddir = uri_escape("$dir", "^A-Za-z");
	$dir =~ s/^.*\///;
	$dir =~ s/&/&amp;/g;

	print "<tr>";
	print "<td><a name='a" . $anchorcounter . "'></a>" .
	    "<a class='$cssdirclass' href='editplaylist.pl?" .
	    "action=addbrowse&amp;playlist=$playlist" .
	    "&amp;dir=$escapeddir'>$dir</a></td>";
	print "<td align='right'><a class='$cssdirclass'" .
	    "href='editplaylist.pl?action=adddir&amp;playlist=$playlist" .
	    "&amp;toadd=$escapeddir&amp;dir=$givendir#a" . $anchorcounter++ . "'>Add</a></td>";
	print "</tr>\n";
    }
    
    foreach my $file (@files) {
	$file =~ s/\Q$config{mediadir}$givendir\E//;
	print "<tr>";
	if (($file =~ /mp3$/i) || ($file =~ /ogg$/i)) {
	    my $escapeddir = "$givendir$file";
	    $escapeddir =~ s/\Q$config{mediadir}\E//;
	    $escapeddir = uri_escape("$escapeddir", "^A-Za-z");
	    if ($cssfileclass eq 'file') {
		$cssfileclass = 'file2';
	    } else {
		$cssfileclass = 'file';
	    }
	    my $escapedfile = $file;
	    $escapedfile =~ s/&/&amp;/g;
	    print "<td><a name='a" . $anchorcounter . "'></a>" .
		"<a class='$cssfileclass' href='fileinfo.pl?file=$escapeddir'>" .
		"$escapedfile</a></td>";
	    print "<td align='right'><a class='$cssfileclass' href='editplaylist.pl" .
		"?action=addfile&amp;playlist=$playlist&amp;toadd=$escapeddir&dir=$givendir#a" .
		$anchorcounter++ . "'>Add</a></td>";
	}# elsif(($file =~ /m3u$/) || ($file =~ /pls$/)) {
#	    my $escapeddir = "$givendir$file";
#	    $escapeddir =~ s/\Q$config{mediadir}\E//;
#	    $escapeddir = uri_escape("$escapeddir", "^A-Za-z");
#	    if ($csslistclass eq 'playlist') {
#		$csslistclass = 'playlist2';
#	    } else {
#		$csslistclass = 'playlist';
#	    }
#	    my $escapedfile = $file;
#	    $escapedfile =~ s/&/&amp;/g;
#	    print "<td><a class='$csslistclass' href='viewlist.pl?list=$escapeddir'>$escapedfile</a></td>";
#	    print "<td><a class='$csslistclass' href='oyster-gui.pl?votelist=$escapeddir' target='curplay'>Vote</a></td>";
#	} 
	print "</tr>\n";
    }

    print "</table>";
    print end_html;


}
