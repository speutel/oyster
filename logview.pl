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
print "<td align='center' width='25%'><a href='browse.pl'>Browse</a></td>";
print "<td align='center' width='25%'><a href='search.pl'>Search</a></td>";
print "<td align='center' width='25%'><a href='blacklist.pl'>Blacklist</a></td>";
print "<td align='center' width='25%'><a href='logview.pl'>Logfile</a></td>";
print "</tr></table>";
print "<hr>";

my %config = oyster::conf->get_config('oyster.conf');

open (LOG, "${config{'savedir'}}log");

my $next = '';
my $cssclass = 'file2';

print "<table>";

while ((!($next eq '')) || (my $line = <LOG>)) {
    if (!($next eq '')) {
	$line = $next;
	$next = '';
    }
    my ($year, $month, $day, $hour, $minute, $second, $playreason, $filename);
    chomp($line);
    $_ = $line;
    ($year, $month, $day, $hour, $minute, $second, $playreason, $filename) =
	m@^([0-9]{4})([0-9]{2})([0-9]{2})\-([0-9]{2})([0-9]{2})([0-9]{2})\ ([^\ ]*)\ (.*)$@;
#    print "$line<br>";
    if (($playreason eq 'PLAYLIST') || ($playreason eq 'LASTVOTES') || ($playreason eq 'VOTED')) {
	$line = <LOG>;
	chomp($line);
	$_ = $line;
	my ($endreason, $filename2);
	($endreason, $filename2) = m@^[0-9]{8}\-[0-9]{6}\ ([^\ ]*)\ (.*)$@;
	my %tag = oyster::taginfo->get_tag($filename);
	if ($cssclass eq 'file') {
	    $cssclass = 'file2';
	} else {
	    $cssclass = 'file';
	}
	if ($filename eq $filename2) {
	    $filename =~ s/^\Q$config{'mediadir'}\E//;
	    my $escapedfilename = uri_escape("$filename", "^A-Za-z");
	    print "<tr><td>$playreason</td><td>$endreason</td>";
	    print "<td><a class='$cssclass' href='fileinfo.pl?file=$escapedfilename'>$tag{'display'}</a></td></tr>\n";
	} else {
	    my $escapedfilename = uri_escape("$filename", "^A-Za-z");
	    print "<tr><td>$playreason</td><td></td>";
	    print "<td><a class='$cssclass' href='fileinfo.pl?file=$escapedfilename'>$tag{'display'}</td></tr>\n";
	    $next = $line;
	}
    }
#    print $line;
}

print "</table>";
print end_html;