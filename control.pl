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

print "<a href='control.pl' style='position:absolute; top:2px; right:2px'><img src='refresh.gif' border='0'></a>";

print "<table width='80%' style='margin-left:auto; margin-right:auto;'>";
print "<tr><td align='left' width='30%'><a href='control.pl?action=start'>Start</a></td>";
print "<td></td>";
print "<td align='right' width='30%'><a href='control.pl?action=stop'>Stop</a></td>";
print "</tr></table>\n";

my $volume = `aumix -w q`;
$volume =~ s/^pcm\ //;
$volume =~ s/,.*//;

print "<table width='80%' style='margin-left:auto; margin-right:auto;'>";
print "<tr><td align='left' width='40%'><a href='control.pl?vol=down'>Volume Down</a></td>";
print "<td align='center' width='20%'><a href='control.pl?vol=50'>$volume</a></td>";
print "<td align='right' width='40%'><a href='control.pl?vol=up'>Volume Up</a></td>";
print "</tr></table>\n";

print end_html;

