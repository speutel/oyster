#!/usr/bin/perl
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

if (param('action')) {
    $status = oyster::fifocontrol->do_action(param('action'), param('file'), $status);
}

if (param('vote')) {
    oyster::fifocontrol->do_vote(param('vote'));
}

print
    header,
    start_html(-title=>'Oyster-GUI',
	       -style=>{'src'=>"themes/${config{'theme'}}/layout.css"},
	       -head=>[CGI::meta({-http_equiv => 'Content-Type',
				 -content    => 'text/html; charset=iso-8859-1'}),
		       CGI::meta({-http_equiv => 'refresh',
				 -content    => '30; URL=oyster-gui.pl'})]
	       );

print h1('Oyster');
print "<a href='oyster-gui.pl' style='position:absolute; top:2px; right:2px'><img src='themes/${config{'theme'}}/refresh.png' border='0' alt='Refresh'></a>";

if ((!(-e "$basedir")) || ($action eq 'stop')) {
    print "<p>Oyster has not been started yet!</p>";
    print "<p><a href='oyster-gui.pl?action=start'>Start</a></p>";
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
$info = "/$info";
$info = uri_escape("$info", "^A-Za-z");

my $statusstr = '';
if ($status eq 'paused') {
    $statusstr = ' (Paused)';
}

print "<table width='100%' border='1'>";
print "<tr><td><strong>Now playing:</strong></td><td align='center'><strong>Score</strong></td></tr>";
print "<tr><td><strong><a class='file' href='fileinfo.pl?file=$info' target='browse'>$display</a>$statusstr</strong></td>";
print "<td align='center' style='padding-left:10px; padding-right:10px'><a href='oyster-gui.pl?action=scoredown&amp;file=$info'><img src='themes/${config{'theme'}}/scoredownfile.png' border='0' alt='-'></a> ";
print "<strong>$tag{'score'}</strong> ";
print "<a href='oyster-gui.pl?action=scoreup&amp;file=$info'><img src='themes/${config{'theme'}}/scoreupfile.png' border='0' alt='+'></a></td></tr>";
print "</table>\n";

#print "<p><a href='oyster-gui.pl?action=scoreup&amp;file=$info'>Score up</a></p>";
#print "<p><a href='oyster-gui.pl?action=scoredown&amp;file=$info'>Score down</a></p>\n";

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
		my $escapedtitle = uri_escape("$title", "^A-Za-z");
		print "<tr><td><a class='file' href='fileinfo.pl?file=$escapedtitle' target='browse'>$display</a></td><td align='center'>$numvotes</td><td><a href='oyster-gui.pl?action=unvote&file=$escapedtitle'>Unvote</a></td></tr>\n";
	    }
	}
	$maxvotes--;
    }
    print "</table>";
}

close VOTES;

print end_html;
