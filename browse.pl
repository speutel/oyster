#!/usr/bin/perl
use CGI qw/:standard/;

print header, start_html('Oyster-GUI');

my $basedir='/Multimedia/Audio/';
my $rootdir=$basedir;

if (param()) {
    $basedir=param('dir') . "/";
    $basedir =~ s@//$@/@;
    $basedir =~ s/\.\.\///g;
    $basedir = $rootdir if (($basedir eq "..") || ($basedir eq ""));
}

$basedir = $rootdir if (!($basedir =~ /^\Q$rootdir\E/));

print h1("Aktuelles Verzeichnis: $basedir");

my $globdir = $basedir;
$globdir =~ s/\ /\\\ /g;
my @entries = <$globdir*>;

my $topdir = $basedir;
$topdir =~ s/\/[^\/]*\/$//;

print "<a href='browse.pl?dir=$topdir/'>Eine Ebene h&ouml;her</a><br>";
print "<table>";

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
    print "<td>$file</td>";
    print "<td><a href='vote.pl?vote=$basedir$file'>Vote</a></td>";
    print "</tr>";
}

print "</table>";
