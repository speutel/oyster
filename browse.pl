#!/usr/bin/perl
use CGI qw/:standard -no_xhtml/;
use URI::Escape;
use strict;
use oyster::conf;

print header, start_html(-title=>'Oyster-GUI',
			 -style=>{'src'=>'layout.css'},
			 -head=>CGI::meta({-http_equiv => 'Content-Type',
                                           -content    => 'text/html; charset=iso-8859-1'}));

print "<table width='100%'><tr>";
print "<td align='center' width='50%'><a href='browse.pl'>Browse</a></td>";
print "<td align='center' width='50%'><a href='search.pl'>Search</a></td>";
print "</tr></table>";
print "<hr>";

my %config = oyster::conf->get_config('oyster.conf');

my $basedir = $config{'mediadir'};
my $rootdir=$basedir;

if (param()) {
    $basedir=param('dir') . "/";
    $basedir =~ s@//$@/@;
    $basedir =~ s/\.\.\///g;
    $basedir = $rootdir if (($basedir eq "..") || ($basedir eq ""));
}

$basedir = $rootdir if (!($basedir =~ /^\Q$rootdir\E/));

my $shortdir = $basedir;
$shortdir =~ s/^\Q$rootdir\E//;

if (!($basedir eq $rootdir)) {

    print "<p><strong>Current directory: ";

    my @dirs = split(/\//, $shortdir);
    my $incdir = '';
    foreach my $partdir (@dirs) {
	my $escapeddir = uri_escape("$rootdir$incdir$partdir", "^A-Za-z");
	print "<a href='browse.pl?dir=$escapeddir'>$partdir</a> / ";
	$incdir = $incdir . "$partdir/";
    }

    print "</strong></p>";

    my $topdir = $basedir;
    $topdir =~ s/\/[^\/]*\/$//;

    my $escapeddir = uri_escape($topdir, "^A-Za-z");
    print "<a href='browse.pl?dir=$escapeddir'>One level up</a><br><br>";

}

my $globdir = $basedir;
$globdir =~ s/\ /\\\ /g;
my @entries = <$globdir*>;

print "<table width='100%'>";

my @files = my @dirs = ();

foreach my $entry (@entries) {
    if (-d "$entry") {
	push (@dirs, "$entry");
    } elsif (-f "$entry") {
	push (@files, "$entry");
    }
}

foreach my $dir (@dirs) {
    $dir =~ s/\Q$basedir\E//;
    my $escapeddir = uri_escape("$basedir$dir", "^A-Za-z");
    print "<tr>";
    print "<td><a href='browse.pl?dir=$escapeddir'>$dir</a></td>";
    print "<td></td>";
    print "</tr>\n";
}

my $cssclass = 'file2';

foreach my $file (@files) {
    $file =~ s/\Q$basedir\E//;
    print "<tr>";
    if (($file =~ /mp3$/) || ($file =~ /ogg$/)) {
	my $escapeddir = uri_escape("$basedir$file", "^A-Za-z");
	if ($cssclass eq 'file') {
	    $cssclass = 'file2';
	} else {
	    $cssclass = 'file';
	}
	print "<td><a class='$cssclass' href='fileinfo.pl?file=$escapeddir'>$file</a></td>";
	print "<td><a class='$cssclass' href='vote.pl?vote=$escapeddir'>Vote</a></td>";
    } else {
	print "<td>$file</td>";
	print "<td></td>";
    }
    print "</tr>\n";
}

print "</table>";
