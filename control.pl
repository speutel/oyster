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

print "<table border='0' width='80%' align='center'><tr>";
print "<td align='center'><a href='oyster-gui.pl?action=start' target='curplay'><img src='themes/${config{theme}}/play.png' border='0' alt='Start'></a></td>";
print "<td align='center'><a href='oyster-gui.pl?action=stop' target='curplay'><img src='themes/${config{theme}}/stop.png' border='0' alt='Stop'></a></td>";
print "<td>&nbsp;</td>";
print "<td rowspan='2' align='center' style='line-height:180%'><a href='control.pl?vol=up'><img src='themes/${config{theme}}/volup.png' border='0' alt='Volume Up'></a><br>";
print "<a href='control.pl?vol=50'>Volume $volume</a><br>";
print "<a href='control.pl?vol=down'><img src='themes/${config{theme}}/voldown.png' border='0' alt='Volume Down'></a></td>";
print "</tr><tr>";
print "<td align='center'><a href='oyster-gui.pl?action=pause' target='curplay'><img src='themes/${config{theme}}/pause.png' border='0' alt='Pause'></a></td>";
print "<td align='center'><a href='oyster-gui.pl?action=prev' target='curplay'><img src='themes/${config{theme}}/prev.png' border='0' alt='Prev'></a></td>";
print "<td align='center'><a href='oyster-gui.pl?action=skip' target='curplay'><img src='themes/${config{theme}}/skip.png' border='0' alt='Skip'></a></td>";
print "</tr></table>";

print end_html;

