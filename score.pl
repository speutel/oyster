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
use oyster::taginfo;
use oyster::fifocontrol;
use oyster::common;

my %config = oyster::conf->get_config('oyster.conf');
my $playlist = oyster::conf->get_playlist();

if (param('action')) {
    oyster::fifocontrol->do_action(param('action'), param('file'), '');
}

oyster::common->navigation_header();

my %score = ();

open (LASTVOTES, "${config{'savedir'}}scores/$playlist") or die $!;
my $line = <LASTVOTES>;
while ($line = <LASTVOTES>) {
    chomp($line);
    if ($score{$line}) {
	$score{$line}++;
    } else {
	$score{$line} = 1;
    }
}
close (LASTVOTES);

print "<table width='100%'>";
print "<tr><th>Song</th><th width='75'>Score</th></tr>";

my $cssclass='file2';

my $maxscore = (sort {$b <=> $a} values(%score))[0];

while ($maxscore > 0) {

    my $printed = 0;

    my @files = ();

    foreach my $key (keys(%score)) {
	if ($score{$key} == $maxscore) { 
	    push(@files, $key);
	}
    }

    @files = sort(@files);

    foreach my $file (@files) {

	$printed = 1;

	my $escapedfile = $file;
	$escapedfile =~ s/\Q$config{'mediadir'}\E//;
	$escapedfile = uri_escape("/$escapedfile", "^A-Za-z");
	my $display = oyster::taginfo->get_tag_light($file);
	
	# $cssclass changes to give each other file
	# another color
	
	if ($cssclass eq 'file') {
	    $cssclass = 'file2';
	} else {
	    $cssclass = 'file';
	}
	
	print "<tr><td><a href='oyster-gui.pl?action=enqueue&amp;file=$escapedfile' target='curplay' title='Enqueue'><img src='themes/${config{'theme'}}/enqueue${cssclass}.png' border='0' alt='Enqueue'/></a> <a class='$cssclass' href='fileinfo.pl?file=$escapedfile'>$display</a></td>";
	print "<td align='center'><a class= '$cssclass' href='score.pl?action=scoredown&amp;file=$escapedfile' title='Score down'><img src='themes/${config{'theme'}}/scoredown${cssclass}.png' border='0' alt='-'></a> <span class='$cssclass'><strong>$score{$file}</strong></span>";
	print " <a class='$cssclass' href='score.pl?action=scoreup&amp;file=$escapedfile' title='Score up'><img src='themes/${config{'theme'}}/scoreup${cssclass}.png' border='0' alt='+'></a></td></tr>";	
    }

    $maxscore--;

    if ($printed) { print "<tr><td colspan=2>&nbsp;</td></tr>"; }

}


foreach my $key (sort {$b <=> $a} values(%score)) {

}

print "</table>";

print end_html;
