#!/usr/bin/perl
use CGI qw/:standard/;

print header, start_html(-title=>'Oyster-GUI',-style=>{'src'=>'layout.css'});
print "<meta http-equiv='refresh' content='0; URL=oyster-gui.pl'>";

if (param()) {
    $volume=param('vol');
}

if ($volume eq 'down') {
    system ('/usr/bin/aumix -w -5');
} elsif ($volume eq '50') {
    system ('/usr/bin/aumix -w 50');
} elsif ($volume eq 'up') {
    system ('/usr/bin/aumix -w +5');
}

print end_html;
