#!/usr/bin/perl
use CGI qw/:standard/;
use URI::Escape;
use strict;

print header, start_html(-title=>'Oyster-GUI',
			 -style=>{'src'=>'layout.css'},
			 -head=>CGI::meta({-http_equiv => 'Content-Type',
                                           -content    => 'text/html; charset=iso-8859-1'}));

print "<table width='100%'><tr>";
print "<td align='center' width='50%'><a href='browse.pl'>Browse</a></td>";
print "<td align='center' width='50%'><a href='search.pl'>Search</a></td>";
print "</tr></table>";
print "<hr>";

my $basedir = '/Multimedia/Audio/';
my $rootdir=$basedir;
my $search;

if (param()) {
    $search=param('search');
    print "<form action='search.pl'><input type='text' name='search' value='$search'>";
    print "<input type='submit' value='Search'></form>";
    open (LIST, "lists/default");
    my @list = <LIST>;
    foreach my $line (@list) {
	chomp($line);
	$line =~ s/\Q$basedir\E//;
	if ($line =~ /\Q$search\E/i) {
	    my @dirs = split(/\//, $line);
	    my $incdir = '';
	    foreach my $partdir (@dirs) {
		my $escapeddir = uri_escape("$rootdir$incdir$partdir", "^A-Za-z");
		if (($partdir =~ /mp3$/) || ($partdir =~ /ogg$/)) {
		    print "<a href='fileinfo.pl?file=$escapeddir'>$partdir</a>";
		} else {
		    print "<a href='browse.pl?dir=$escapeddir'>$partdir</a> / ";
		}
		$incdir = $incdir . "$partdir/";
	    }
	    print "<br><br>\n";
	}
    }
} else {
    print "<form action='search.pl'><input type='text' name='search'>";
    print "<input type='submit' value='Search'></form>";
}
