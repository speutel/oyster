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

my %config = oyster::conf->get_config('oyster.conf');
my $basedir = $config{'basedir'};

open(STATUS, "${basedir}status");
my $status = <STATUS>;
chomp($status);
close(STATUS);

my $action = param('action') || '';

my $mediadir = $config{'mediadir'};
$mediadir =~ s/\/$//;

my $file = param('file') || '';

if (param('action')) {
	$status = oyster::fifocontrol->do_action(param('action'), $file, $status);
}

if (param('vote')) {
	oyster::fifocontrol->do_vote(param('vote'));
}

if (param('votelist')) {
	oyster::fifocontrol->do_votelist(param('votelist'));
}

my $frames = 1;
my $framestr = '';
my $framestr2 = '';

if ((param('frames') && (param('frames') eq 'no'))) {
	$frames = 0;
	$framestr = '?frames=no';
	$framestr2 = '&frames=no';
}

print header,
start_html(-title=>'Oyster-GUI',
	-style=>{'src'=>"themes/${config{'theme'}}/layout.css"},
	-head=>[CGI::meta({-http_equiv => 'Content-Type',
			-content    => 'text/html; charset=iso-8859-1'}),
	CGI::meta({-http_equiv => 'refresh',
			-content    => "30; URL=oyster-gui.pl$framestr"})]
);

if (! $frames) {
	oyster::common->noframe_navigation_noheader();
}

print h1('Oyster');
print "<a href='oyster-gui.pl${framestr}' style='position:absolute; top:2px; right:2px' title='Refresh'>";
print "<img src='themes/${config{'theme'}}/refresh.png' border='0' alt='Refresh'></a>";

if ((!(-e "$basedir")) || ($action eq 'stop')) {
	print p('Oyster has not been started yet!');
	print p(a({href=>"oyster-gui.pl?action=start${framestr2}"},'Start'));
	print end_html;
	exit 0;
}

if (!(-e "${basedir}info")) {
	print p("Oyster has not created needed files in ${basedir}");
	print end_html;
	exit 0;
}

open(INFO, "${basedir}info");
my $info = <INFO>;
chomp($info);
$info =~ s/^np:\ //;
close(INFO);

my $display = oyster::taginfo->get_tag_light($info);
my %tag = oyster::taginfo->get_tag($info);

$info =~ s/^\Q$config{'mediadir'}\E//;
$info = uri_escape("/$info", "^A-Za-z");

my $playlist = oyster::conf->get_playlist();
my $playreason = `tail -n 1 logs/$playlist`;
chomp($playreason);
$playreason =~ s/^[^\ ]*\ //;
$playreason =~ s/\ .*$//;

if ($playreason eq 'PLAYLIST') {
	$playreason = '(random)';
} elsif ($playreason eq 'SCORED') {
	$playreason = '(scored)';
} elsif ($playreason eq 'ENQUEUED') {
	$playreason = '(enqueued)';
} elsif ($playreason eq 'VOTED') {
	$playreason = '(voted)';
}

my $statusstr = '';
if ($status eq 'paused') {
	$statusstr = " " . a({href=>"oyster-gui.pl?action=pause${framestr2}"},'Paused');
}

print "<table width='100%' border='0'>";
print "<tr><td><strong>Now playing $playreason:</strong></td><td align='center' width='75'><strong>Score</strong></td></tr>";
print "<tr><td>";
print strong(a({class=>'file', href=>"fileinfo.pl?file=${info}${framestr2}", target=>'browse', title=>'View details'},$display));
print $statusstr . "</td>";
print "<td align='center' style='padding-left:10px; padding-right:10px'>";
print a({href=>"oyster-gui.pl?action=scoredown&file=$info${framestr2}", title=>'Score down'},
	img({src=>"themes/${config{'theme'}}/scoredownfile.png", border=>'0', alt=>'-'}));
print " " . strong($tag{'score'}) . " ";
print a({href=>"oyster-gui.pl?action=scoreup&file=$info${framestr2}", title=>'Score up'},
	img({src=>"themes/${config{'theme'}}/scoreupfile.png", border=>'0', alt=>'+'}));
print "</td></tr></table>\n";

open (VOTES, "${basedir}votes");
my @votes = <VOTES>;

if (-s "${basedir}votes") {
	my @workvotes = @votes;
	my $maxvotes = 0;

	foreach my $vote (@workvotes) {
		$vote =~ /\,([0-9]*)$/;
		$maxvotes = $1 if ($1 > $maxvotes);
	}

	print "<table width='100%' style='margin-top:3em;'><tr>";
	print "<th width='70%' align='left'>Voted File</th><th align='center'>Num of votes</th><th></th></tr>";

	while ($maxvotes > 0) {
		foreach my $vote (@workvotes) {
			chomp ($vote);
			$vote =~ /(.*),([0-9]*)/;
			my ($numvotes, $title);
			$title = $1;
			$numvotes = $2;
			if ($numvotes == $maxvotes) {
				my $display = oyster::taginfo->get_tag_light($title);
				$title =~ s/^\Q$mediadir\E//;
				my $escapedtitle = uri_escape($title, "^A-Za-z");
				print "<tr><td>";
				print a({class=>'file', href=>"fileinfo.pl?file=$escapedtitle${framestr2}", target=>'browse'},$display);
				print "</td><td align='center'>$numvotes</td><td>";
				print a({href=>"oyster-gui.pl?action=unvote&file=$escapedtitle${framestr2}"},'Unvote');
				print "</td></tr>\n";
			}
		}
		$maxvotes--;
	}
	print "</table>";
}

close VOTES;

print end_html;
