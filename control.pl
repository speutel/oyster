#!/usr/bin/perl
use CGI qw/:standard -no_xhtml/;
use URI::Escape;
use strict;
use oyster::conf;

my %config = oyster::conf->get_config('oyster.conf');

if (param()) {
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
	       -style=>{'src'=>"themes/${config{'theme'}}/layout.css"},
	       -head=>CGI::meta({-http_equiv => 'Content-Type',
				 -content    => 'text/html; charset=iso-8859-1'}));

print "<a href='control.pl' style='position:absolute; top:2px; right:2px'><img src='themes/${config{'theme'}}/refresh.png' border='0' alt='Refresh'></a>";

my $volume = `aumix -w q`;
$volume =~ s/^pcm\ //;
$volume =~ s/,.*//;

print "<table border='0' width='80%' align='center'><tr><td align='center'><a href='oyster-gui.pl?action=start' target='curplay'>Start</a></td><td align='center'><a href='oyster-gui.pl?action=stop' target='curplay'>Stop</a></td><td rowspan='2' align='center'><a href='control.pl?vol=up'><img src='themes/${config{theme}}/volup.png' border='0'></a><br>Volume $volume<br><a href='control.pl?vol=down'><img src='themes/${config{theme}}/voldown.png' border='0'></a></td></tr><tr><td align='center'><a href='oyster-gui.pl?action=pause' target='curplay'>Pause</td><td align='center'><a href='oyster-gui.pl?action=skip' target='curplay'>Skip</a></td></tr></table>";


#print "<table width='80%' style='margin-left:auto; margin-right:auto;'>";
#print "<tr><td align='left' width='30%'><a href='oyster-gui.pl?action=start' target='curplay'>Start</a></td>";
#print "<td align='left'><a href='oyster-gui.pl?action=pause' target='curplay'>Pause</a></td>";
#print "<td align='right'><a href='oyster-gui.pl?action=skip' target='curplay'>Skip</a></td>";
#print "<td align='right' width='30%'><a href='oyster-gui.pl?action=stop' target='curplay'>Stop</a></td>";
#print "</tr></table>\n";


#print "<table width='80%' style='margin-left:auto; margin-right:auto;'>";
#print "<tr><td align='left' width='40%'><a href='control.pl?vol=down'>Volume Down</a></td>";
#print "<td align='center' width='20%'><a href='control.pl?vol=50'>$volume</a></td>";
#print "<td align='right' width='40%'><a href='control.pl?vol=up'>Volume Up</a></td>";
#print "</tr></table>\n";

print end_html;

