#!/usr/bin/perl
use CGI qw/:standard/;
use URI::Escape;

print header, start_html(-title=>'Oyster-GUI',-style=>{'src'=>'layout.css'});

my $basedir = '/Multimedia/Audio/';
my $rootdir=$basedir;

if (param()) {
    $search=param('search');
    print "<form action='search.pl'><input type='text' name='search' value='$search'>";
    print "<input type='submit' value='Search'></form>";
    open (LIST, "lists/default");
    @list = <LIST>;
    foreach $line (@list) {
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
	    print "<br>\n";
	}
    }
} else {
    print "<form action='search.pl'><input type='text' name='search'>";
    print "<input type='submit' value='Search'></form>";
}
