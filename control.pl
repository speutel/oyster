#!/usr/bin/perl
use CGI qw/:standard -no_xhtml/;
use URI::Escape;
use strict;

if (param()) {
    my $action=param('action');
    if ($action eq 'start') {
	system("perl oyster.pl &");
    } elsif ($action eq 'stop') {
	open (CONTROL, '>/tmp/oyster/control');
	print CONTROL 'QUIT';
	close CONTROL;
    } elsif ($action eq 'skip') {
	open (CONTROL, '>/tmp/oyster/control');
	print CONTROL 'NEXT';
	close CONTROL;
    }
    my $volume=param('vol');
    if ($volume eq 'down') {
	system ('/usr/bin/aumix -w -5');
    } elsif ($volume eq '50') {
	system ('/usr/bin/aumix -w 50');
    } elsif ($volume eq 'up') {
	system ('/usr/bin/aumix -w +5');
    }
	
}	

print
    header,
    start_html(-title=>'Oyster-GUI',
	       -style=>{'src'=>'layout.css'},
	       -head=>CGI::meta({-http_equiv => 'Content-Type',
				 -content    => 'text/html; charset=iso-8859-1'}));

print "<table width='100%'>";
print "<tr><td align='center' width='30%'><a href='control.pl?action=start'>Start</a></td>";
print "<td align='center' width='40%'><a href='control.pl?action=skip'>Skip</a></td>";
print "<td align='center' width='30%'><a href='control.pl?action=stop'>Stop</a></td>";
print "</tr></table>\n";

my $volume = `aumix -w q`;
$volume =~ s/^pcm\ //;
$volume =~ s/,.*//;

print "<table width='100%'>";
print "<tr><td align='center' width='40%'><a href='control.pl?vol=down'>Volume Down</a></td>";
print "<td align='center' width='20%'><a href='control.pl?vol=50'>$volume</a></td>";
print "<td align='center' width='40%'><a href='control.pl?vol=up'>Volume Up</a></td>";
print "</tr></table>\n";

open (VOTES, '/tmp/oyster/votes');
my @votes = <VOTES>;

if (-s '/tmp/oyster/votes') {
    print "<table width='100%' style='margin-top:3em;'><tr>";
    print "<th width='70%' align='left'>Voted File</th><th align='center'>Num of votes</th>";
    foreach my $vote (@votes) {
	chomp ($vote);
	my ($numvotes, $title);
	$_ = $vote;
	($title, $numvotes) = m@.*\/(.*),(.*)@;
	$title =~ s/\.mp3$//;
	$title =~ s/\.ogg$//;
	my $escapedvote = $vote;
	$escapedvote =~ s/,[1-9]*$//;
	$escapedvote = uri_escape("$escapedvote", "^A-Za-z");
	print "<tr><td><a href='fileinfo.pl?file=$escapedvote' target='browse'>$title</a></td><td align='center'>$numvotes</td></tr>\n";
    }
    print "</table>";
}

print end_html;

