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
use File::Find;

my %config = oyster::conf->get_config('oyster.conf');

my $frames = 1;
my $framestr = '';

if ((param('frames') && (param('frames') eq 'no'))) {
	$frames = 0;
	$framestr = '&frames=no';
}

if ($frames) {
	oyster::common->navigation_header();
} else {
	oyster::common->noframe_navigation();
	print h1('Edit Playlist');
}

my $cssdirclass = 'dir2';
my $cssfileclass = 'file2';
my $action = param('action') || '';
my $playlist = param('playlist') || '';
my @playlist = ();
my @results = ();

if (($action eq 'edit') || ($action eq 'deletefile') ||($action eq 'deletedir')) {
	my $delfile = param('file') || '';
	my $deldir = param('dir') || '';

	print h1(a({href=>"editplaylist.pl?action=edit&playlist=${playlist}${framestr}"},$playlist));
	print a({href=>"editplaylist.pl?action=addbrowse&playlist=$playlist&dir=/${framestr}"},
		'Add files to this list...'),br;
	print a({href=>"editplaylist.pl?action=addlist&playlist=$playlist"},
		'Add another playlist to this list...'),br;
	print a({href=>"editplaylist.pl?action=search&playlist=$playlist${framestr}"},
      'Search for files to add...'),br,br;

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
	close (PLAYLIST);

	@playlist = sort @playlist;

	if (($action eq 'deletefile') || ($action eq 'deletedir')) {

		# Write new playlist

		open (PLAYLIST, ">$config{savedir}lists/$playlist") || error_msg();

		sub error_msg {
			print strong("Error: Could not save playlist $playlist!");
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

		# Reload playlist, if currenty running

		if ($playlist eq $config{'playlist'}) {
			oyster::fifocontrol->do_action('loadlist', $playlist, '');
		}

	}

	listdir('/',0);

} elsif ($action eq 'addbrowse') {

	browse();

} elsif (($action eq 'adddir') || ($action eq 'addfile') || ($action eq 'addlistsave')) {
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
	} elsif ($action eq 'addlistsave') {
		open (ADDLIST, "$config{savedir}lists/$toadd") or die $!;
		while (my $file = <ADDLIST>) {
			$filelist{$file} = 1;
		}
	}

	open (FILELIST, ">$config{savedir}lists/$playlist") || error_msg();

	sub error_msg {
		print strong("Error: Could not save playlist $playlist!");
		print end_html;
		exit 0;
	}

	foreach my $key (sort (keys %filelist)) {
		print FILELIST $key;
		chomp($key);
		$key =~ s/^\Q$config{mediadir}\E/\//;
		push (@playlist, $key);
	}
	close(FILELIST);

	# Reload playlist, if currenty running

	if ($playlist eq $config{'playlist'}) {
		oyster::fifocontrol->do_action('loadlist', $playlist, '');
	}

	if (($action eq 'adddir') || ($action eq 'addfile')) {
		browse();
	} elsif ($action eq 'addlistsave') {
		print h1(a({href=>"editplaylist.pl?action=edit&playlist=${playlist}${framestr}"},$playlist));
		print a({href=>"editplaylist.pl?action=addbrowse&playlist=$playlist&dir=/${framestr}"},
			'Add files to this list...'),br;
		print a({href=>"editplaylist.pl?action=addlist&playlist=$playlist"},
			'Add another playlist to this list...'),br;
		print a({href=>"editplaylist.pl?action=search&playlist=$playlist${framestr}"},
			'Search for files to add...'),br,br;
		listdir('/', 0);
	}

} elsif ($action eq 'addlist') {

	my $globdir = "$config{savedir}lists/";
	my @entries = <$globdir*>;

	my @files = ();

	print h1($playlist);

	print h2('Which playlist should be added?');

	foreach my $entry (@entries) {
		if (-f "$entry") {
			$entry =~ s/$globdir//;
			if ($entry ne $playlist) {
				print a({-href=>"editplaylist.pl?action=addlistsave" .
						"&playlist=$playlist&toadd=$entry${framestr}"},$entry),br;
			}
		}
	}

} elsif ($action eq 'search') {

	searchform();

} elsif (param('search')) {

	search();

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

			if ($cssdirclass eq 'dir') {
				$cssdirclass = 'dir2';
			} else {
				$cssdirclass = 'dir';
			}

			if (!($basepath eq '/')) {
				print "<div style='padding-left: 1em;'>";
				print "<table width='100%'><tr><td>";
				$escapeddir = uri_escape("$basepath$cutnewpath", "^A-Za-z");
				print b({-class=>$cssdirclass}, $cutnewpath);
				$newpath = "$basepath$newpath";
			}  else {
				print "<table width='100%'><tr><td>";
				$escapeddir = uri_escape("/$cutnewpath", "^A-Za-z");
				print b({-class=>$cssdirclass}, $cutnewpath);
				$newpath = "/$newpath";
			}

			print "</td><td align='right'>";
			print a({
					class=>$cssdirclass,
					href=>"editplaylist.pl?action=deletedir&dir=$escapeddir&" .
					"playlist=${playlist}${framestr}"
				}, 'Delete');

			print "</td></tr></table>";

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

				# $cssfileclass changes to give each other file
				# another color

				if ($cssfileclass eq 'file') {
					$cssfileclass = 'file2';
				} else {
					$cssfileclass = 'file';
				}
				print "<table width='100%'><tr>";
				print "<td align='left'>";

				print a({href=>"fileinfo.pl?file=${escapedfile}${framestr}",
						class=>$cssfileclass}, $nameonly);

				print "</td>";

				print "<td align='right'>";

				print a({href=>"editplaylist.pl?action=deletefile" .
						"&file=$escapedfile&playlist=${playlist}${framestr}",
						class=>$cssfileclass}, 'Delete');

				print "</td>";

				print "</tr></table>\n";
				$counter++;
			}
			print "</div>\n";
		}
	}

	return ($counter);

}

sub browse {

	print h1(a({href=>"editplaylist.pl?action=edit&playlist=${playlist}${framestr}"},$playlist));

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
			print a({href=>"editplaylist.pl?action=addbrowse&playlist=$playlist" .
					"&dir=${escapeddir}${framestr}"}, $escapedpartdir);

			print "/ ";
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
		print a({href=>"editplaylist.pl?action=addbrowse" .
				"&playlist=$playlist&dir=${escapeddir}${framestr}"}, 'One level up'), br, br;

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
		print "<td><a name='a" . $anchorcounter . "'></a>";
		print a({class=>$cssdirclass,
				href=>"editplaylist.pl?action=addbrowse&playlist=$playlist" .
				"&dir=${escapeddir}${framestr}"}, $dir);
		print "</td>";

		print "<td align='right'>";
		print a({class=>$cssdirclass,
				href=>"editplaylist.pl?action=adddir&playlist=$playlist" .
				"&toadd=$escapeddir&dir=${givendir}${framestr}#a" . $anchorcounter++}, 'Add');

		print "</td></tr>\n";
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
			print "<td><a name='a" . $anchorcounter . "'></a>";

			print a({class=>$cssfileclass,
					href=>"fileinfo.pl?file=${escapeddir}${framestr}"}, $escapedfile);
			print "</td>";

			print "<td align='right'>";

			print a({class=>$cssfileclass,
					href=>"editplaylist.pl?action=addfile&playlist=$playlist" .
					"&toadd=$escapeddir&dir=${givendir}${framestr}#a" . $anchorcounter++}, 'Add');

		}
		print "</td></tr>\n";
	}

	print "</table>";
	print end_html;


}

sub search {

   my $search = param('search') || '';
	my $searchtype = param('searchtype') || '';
	my $mediadir = $config{'mediadir'};
	$mediadir =~ s/\/$//;

	searchform();

	if ($search ne '') {

		open (LIST, "${config{savedir}}lists/default");
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

   	# Determine maximum depth of directories for
      # further sorting
   
		my $maxdepth = -1;
		foreach my $result (@results) {
			my $line = $result;
			my $counter = 0;
			while ($counter < $maxdepth) {
				$line =~ s/^[^\/]*\///;
				$counter++;
			}                                                                                                                       
			if ($line =~ /\//) {
				$maxdepth++;
			}
		}

		# Sort directories before files in every depth

		while ($maxdepth >= 0) {
			@results = sort_results($maxdepth);
			$maxdepth--;
		}

		# List directory in browser

		if (@results > 0) {
			listsearch('/',0);
		} else {
			print p('No songs found.');
		}

	}

	print end_html;

	exit 0;

}

sub listsearch {

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

			if ($basepath ne '/') {
				my $escapeddir = uri_escape("$basepath$cutnewpath", "^A-Za-z");
				print "<div style='padding-left: 1em;'>";

				print "<table width='100%'><tr><td align='left'>";
				print strong(a({href=>"editplaylist.pl?action=addbrowse&playlist=$playlist&" .
								"dir=${escapeddir}${framestr}"},escapeHTML($cutnewpath)));
				print "</td><td align='right'>";
				print a({href=>"editplaylist.pl?action=adddir&playlist=$playlist" .
						"&toadd=${escapeddir}&dir=${escapeddir}${framestr}"}, 'Add');
				print "</td></tr></table>\n";
				$newpath = "$basepath$newpath";
			}  else {
				my $escapeddir = uri_escape("/$cutnewpath", "^A-Za-z");
				print "<table width='100%'><tr><td align='left'>";
				print strong(a({href=>"editplaylist.pl?action=addbrowse&playlist=$playlist&" .
								"dir=${escapeddir}${framestr}"},escapeHTML($cutnewpath)));
				print "</td><td align='right'>";
				print a({href=>"editplaylist.pl?action=adddir&playlist=$playlist" .
						"&toadd=${escapeddir}&dir=${escapeddir}${framestr}"}, 'Add');
				print "</td></tr></table>\n";
				$newpath = "/$newpath";
			}

			# Call listdir recursive, then quit padding with <div>

			$counter = listsearch($newpath,$counter);
			if (!($basepath eq '/')) {
				print "</div>\n";
			}
		} else {

		# $newpath is a regular file without leading directory

			print "<div style='padding-left: 1em;'>";
			while ($results[$counter] =~ /^\Q$basepath\E/) {

				#	Print all filenames in $basedir

				my $filename = $results[$counter];
				$filename =~ s/^.*\///;
				$filename =~ /(.*)\.(...)$/;
				my $nameonly = $1;
				my $escapedfile = uri_escape("$basepath$filename", "^A-Za-z");
				my $escapeddir = uri_escape($basepath, "^A-Za-z");

				# $cssclass changes to give each other file
				# another color

				if ($cssfileclass eq 'file') {
					$cssfileclass = 'file2';
				} else {
					$cssfileclass = 'file';
				}
				print "<table width='100%'><tr>";
				print "<td align='left'><a href='fileinfo.pl?file=${escapedfile}${framestr}' ";
				print "class='$cssfileclass'>" . escapeHTML($nameonly) . "</a></td>";
				print "<td align='right'>";
				print a({class=>$cssfileclass,
						href=>"editplaylist.pl?action=addfile&playlist=$playlist" .
						"&toadd=${escapedfile}&dir=${escapeddir}${framestr}"}, 'Add');
				print "</td></tr></table>\n";
				$counter++;
			}
			print "</div>\n";
		}
	}

	return ($counter);

}

sub searchform {

   # Create form
	
	my %labels = ('normal' => ' Normal', 'regex' => ' Regular Expression');

	print h1("Add files to " . param('playlist'));

	print start_form;

	my $textfield = textfield(-name=>'search',-default=>'');
	my $radiobuttons = radio_group(-name=>'searchtype',-values=>['normal','regex'],-default=>'normal',
			-linebreak=>'true',-labels=>\%labels);
	my $submit = submit(-value=>'Search',-style=>'margin-left: 2em;');
	print table({-border=>'0'},
			Tr([
				td([$textfield,$radiobuttons,$submit]),
				])
			);

	print hidden('frames','no') if (! $frames);
	print hidden('playlist', $playlist);

	print end_form;


}

sub sort_results {

   # sort_results sorts a directory by
   # "first dirs, then files in a given depth
        
	my $depth = $_[0];
	my (@dirs, @files) = ();

	foreach my $result (@results) {
		my $line = $result;
		my $counter = $depth;
		while ($counter > 0) {
			$line =~ s/^[^\/]*\///;
			$counter--;
		}

	# If $line contains a '/', it is added to @dirs

		if ($line =~ /\//) {
			push (@dirs, $result);
		} else {
			push (@files, $result);
		}
	}

	return (@dirs, @files);

}

