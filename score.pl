#!/usr/bin/perl
use CGI qw/:standard -no_xhtml/;
use URI::Escape;
use strict;
use oyster::conf;
use oyster::taginfo;
use oyster::fifocontrol;

my %config = oyster::conf->get_config('oyster.conf');

if (param('action')) {
    oyster::fifocontrol->do_action(param('action'), param('file'), '');
}

print
    header,
    start_html(-title=>'Oyster-GUI',
	       -style=>{'src'=>"themes/${config{'theme'}}/layout.css"},
	       -head=>CGI::meta({-http_equiv => 'Content-Type',
				 -content    => 'text/html; charset=iso-8859-1'}));

print "<table width='100%'><tr>";
print "<td align='center' width='20%'><a href='browse.pl'>Browse</a></td>";
print "<td align='center' width='20%'><a href='search.pl'>Search</a></td>";
print "<td align='center' width='20%'><a href='blacklist.pl'>Blacklist</a></td>";
print "<td align='center' width='20%'><a href='logview.pl'>Logfile</a></td>";
print "<td align='center' width='20%'><a href='score.pl'>Scoring</a></td>";
print "</tr></table>";
print "<hr>";

my %score = ();

open (LASTVOTES, "${config{'savedir'}}lastvotes") or die $!;
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
print "<tr><th>Song</th><th>Score</th></tr>";

foreach my $key (sort keys (%score)) {
    my $escapedfile = $key;
    $escapedfile =~ s/\Q$config{'mediadir'}\E//;
    $escapedfile = uri_escape("/$escapedfile", "^A-Za-z");
    my $display = oyster::taginfo->get_tag_light($key);
    print "<tr><td><a class='file' href='fileinfo.pl?file=$escapedfile'>$display</a></td>";
    print "<td align='center'><a href='score.pl?action=scoredown&file=$escapedfile'>-</a> $score{$key}";
    print " <a href='score.pl?action=scoreup&file=$escapedfile'>+</a></td></tr>";
}

print "</table>";

print end_html;
