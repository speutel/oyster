#!/usr/bin/perl
use CGI qw/:standard/;

print header, start_html(-title=>'Oyster-GUI',-style=>{'src'=>'layout.css'});

my $basedir = '/Multimedia/Audio/';
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

print h1("$shortdir");

my $globdir = $basedir;
$globdir =~ s/\ /\\\ /g;
my @entries = <$globdir*>;

my $topdir = $basedir;
$topdir =~ s/\/[^\/]*\/$//;

print "<a href='browse.pl?dir=$topdir/'>Eine Ebene h&ouml;her</a><br><br>";
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
    print "<tr>";
    print "<td><a href='browse.pl?dir=$basedir$dir'>$dir</a></td>";
    print "<td></td>";
    print "</tr>";
}

foreach my $file (@files) {
    $file =~ s/\Q$basedir\E//;
    print "<tr>";
    if (($file =~ /mp3$/) || ($file =~ /ogg$/)) {
	print "<td><a href='fileinfo.pl?file=$basedir$file'>$file</a></td>";
	print "<td><a href='vote.pl?vote=$basedir$file'>Vote</a></td>";
    } else {
	print "<td>$file</td>";
	print "<td></td>";
    }
    print "</tr>";
}

print "</table>";
