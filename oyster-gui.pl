#!/usr/bin/perl
use CGI qw/:standard -no_xhtml/;
use URI::Escape;
use strict;
use oyster::conf;
use oyster::taginfo;

my %config = oyster::conf->get_config('oyster.conf');
my $basedir = $config{'basedir'};

open(STATUS, "${basedir}status");
my $status = <STATUS>;
chomp($status);
close(STATUS);

if (param('action')) {
    open (CONTROL, ">${basedir}control");
    my $action=param('action');
    if ($action eq 'skip') {
	print CONTROL 'NEXT';
	sleep 4;
    } elsif ($action eq 'start') {
	system("perl oyster.pl &");
	while (!(-e "${config{'basedir'}}info")) {
	    sleep 1;
	}
    } elsif ($action eq 'stop') {
	print CONTROL "QUIT";
    } elsif ($action eq 'pause') {
	if ($status eq 'paused') {
	    print CONTROL "UNPAUSE";
	    $status = 'playing';
	} elsif ($status eq 'playing') {
	    print CONTROL "PAUSE";
	    $status = 'paused';
	}
    } elsif (($action eq 'scoreup') && (param('file'))) {
	print CONTROL "SCORE + " . param('file');
    } elsif (($action eq 'scoredown') && (param('file'))) {
	print CONTROL "SCORE - " . param('file');
    } 
    close CONTROL;
}

if (param('vote')) {
    my $votefile=param('vote');
    $votefile = $config{'mediadir'} . $votefile;
    open (CONTROL, ">${basedir}control");
    print CONTROL "VOTE $votefile";
    close CONTROL;
    sleep 1;
}

print
    header,
    start_html(-title=>'Oyster-GUI',
	       -style=>{'src'=>"themes/${config{'theme'}}/layout.css"},
	       -head=>CGI::meta({-http_equiv => 'Content-Type',
				 -content    => 'text/html; charset=iso-8859-1'}));

print h1('Oyster');
print "<a href='oyster-gui.pl' style='position:absolute; top:2px; right:2px'><img src='themes/${config{'theme'}}/refresh.png' border='0' alt='Refresh'></a>";

if (!(-e "$basedir")) {
    print "<p>Oyster has not been started yet!</p>";
    print "<p><a href='oyster-gui.pl?action=start'>Start</a></p>";
    print end_html;
    exit 0;
}

print "<meta http-equiv='refresh' content='30; URL=oyster-gui.pl'>";

open(INFO, "${basedir}info");
my $info = <INFO>;
chomp($info);
$info =~ s/^np:\ //;
close(INFO);

my %tag = oyster::taginfo->get_tag($info);

$info =~ s/^\Q$config{'mediadir'}\E//;
$info = "/$info";
$info = uri_escape("$info", "^A-Za-z");

my $statusstr = '';
if ($status eq 'paused') {
    $statusstr = ' (Paused)';
}

print "<strong>Now playing:</strong>";
print "<table width='100%'>";
print "<tr><td><strong><a class='file' href='fileinfo.pl?file=$info' target='browse'>$tag{'display'}</a>$statusstr</strong></td>";
print "<td><a href='oyster-gui.pl?action=skip'>Skip</a></td></tr>";
print "</table>\n";
print "<p><a href='oyster-gui.pl?action=scoreup&amp;file=$info'>Score up</a></p>";
print "<p><a href='oyster-gui.pl?action=scoredown&amp;file=$info'>Score down</a></p>\n";

open (VOTES, "${basedir}votes");
my @votes = <VOTES>;

if (-s "${basedir}votes") {
    print "<table width='100%' style='margin-top:3em;'><tr>";
    print "<th width='70%' align='left'>Voted File</th><th align='center'>Num of votes</th>";
    foreach my $vote (@votes) {
	chomp ($vote);
	my ($numvotes, $title);
	$_ = $vote;
	($title, $numvotes) = m@(.*),([0-9]*)@;
	%tag = oyster::taginfo->get_tag($title);
	$title =~ s/^\Q$config{'mediadir'}\E//;
	my $escapedtitle = uri_escape("$title", "^A-Za-z");
	print "<tr><td><a class='file' href='fileinfo.pl?file=$escapedtitle' target='browse'>$tag{'display'}</a></td><td align='center'>$numvotes</td></tr>\n";
    }
    print "</table>";
}

print end_html;
