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
print "<td align='left' width='30%'><a href='browse.pl'>Browse</a></td>";
print "<td align='center' width='40%'><a href='search.pl'>Search</a></td>";
print "<td align='right' width='30%'><a href='blacklist.pl'>Blacklist</a></td>";
print "</tr></table>";
print "<hr>";

my %config = oyster::conf->get_config('oyster.conf');

my $mediadir = $config{'mediadir'};
my $givendir = '';

if (param('dir')) {
    $givendir=param('dir') . "/";
    $givendir =~ s@//$@/@;
    $givendir =~ s/\.\.\///g;
    $givendir = '' if ($givendir eq "..");
}

if ((!($givendir eq '')) && (-e "$mediadir$givendir")) {

    print "<p><strong>Current directory: ";

    my @dirs = split(/\//, $givendir);
    my $incdir = '';
    foreach my $partdir (@dirs) {
	my $escapeddir = uri_escape("$incdir$partdir", "^A-Za-z");
	print "<a href='browse.pl?dir=$escapeddir'>$partdir</a> / ";
	$incdir = $incdir . "$partdir/";
    }

    print "</strong></p>";

    my $topdir = $givendir;
    $topdir =~ s/\Q$mediadir\E//;
    if ($topdir =~ /^[^\/]*\/$/) {
	$topdir = '';
    } else {
	$topdir =~ s/\/[^\/]*\/$//;
    }

    my $escapeddir = uri_escape($topdir, "^A-Za-z");
    print "<a href='browse.pl?dir=$escapeddir'>One level up</a><br><br>";

} elsif (!(-e "$mediadir$givendir")) {   
    print h1('Error!');
    print "The directory $givendir could not be found.";
    print end_html;
}

my $globdir = "$mediadir$givendir";
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
    $dir =~ s/\Q$mediadir\E//;
    $dir =~ s/^\///;
    my $escapeddir = uri_escape("$dir", "^A-Za-z");
    $dir =~ s/^.*\///;
    print "<tr>";
    print "<td><a href='browse.pl?dir=$escapeddir'>$dir</a></td>";
    print "<td></td>";
    print "</tr>\n";
}

my $cssclass = 'file2';

foreach my $file (@files) {
    $file =~ s/\Q$mediadir$givendir\E//;
    print "<tr>";
    if (($file =~ /mp3$/) || ($file =~ /ogg$/)) {
	my $escapeddir = "$givendir$file";
	$escapeddir =~ s/\Q$mediadir\E//;
	$escapeddir = uri_escape("$escapeddir", "^A-Za-z");
	if ($cssclass eq 'file') {
	    $cssclass = 'file2';
	} else {
	    $cssclass = 'file';
	}
	print "<td><a class='$cssclass' href='fileinfo.pl?file=$escapeddir'>$file</a></td>";
	print "<td><a class='$cssclass' href='oyster-gui.pl?vote=$escapeddir' target='curplay'>Vote</a></td>";
    } else {
	print "<td>$file</td>";
	print "<td></td>";
    }
    print "</tr>\n";
}

print "</table>";
