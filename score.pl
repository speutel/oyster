#!/usr/bin/perl
use CGI qw/:standard -no_xhtml/;
use URI::Escape;
use strict;
use oyster::conf;
use oyster::taginfo;

my %config = oyster::conf->get_config('oyster.conf');

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

print "<table>";
print "<tr><th>Song</th><th>Score</th><th>Control</th></tr>";

foreach my $key (sort keys (%score)) {
    my $escapedfile = $key;
    $escapedfile =~ s/\Q$config{'mediadir'}\E//;
    $escapedfile = uri_escape("/$escapedfile", "^A-Za-z");
    my %tag = oyster::taginfo->get_tag($key);
    print "<tr><td><a class='file' href='fileinfo.pl?file=$escapedfile'>$tag{'display'}</a></td><td align='center'>$score{$key}</td>";
    print "<td><a href='oyster-gui.pl?action=scoredown&file=$escapedfile' target='curplay'>Down</a>";
    print " <a href='oyster-gui.pl?action=scoreup&file=$escapedfile' target='curplay'>Up</a></td></tr>\n";
}

print "</table>";

print end_html;
