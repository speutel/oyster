#!/usr/bin/perl
use CGI qw/:standard -no_xhtml/;
use URI::Escape;
use strict;
use oyster::conf;

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
print "<hr>";

my %config = oyster::conf->get_config('oyster.conf');

my $mediadir = $config{'mediadir'};
my $rootdir=$mediadir;
my $file;

if (param('file')) {
    $mediadir = param('file');
    $mediadir =~ s@//$@/@;
    $mediadir =~ s/\.\.\///g;
    $mediadir = $rootdir if (($mediadir eq "..") || ($mediadir eq ""));
    $file = $mediadir;
    $mediadir =~ s/\/[^\/]*$//;
    $file =~ s/.*\///;
    $mediadir = $rootdir if (($mediadir eq "..") || ($mediadir eq ""));
}

print "<p>Tag-Info for ";

my $subdir = $mediadir;
$subdir =~ s/^\Q$rootdir\E//;
my @dirs = split(/\//, $subdir);
my $incdir = '';
foreach my $partdir (@dirs) {
    my $escapeddir = uri_escape("$incdir$partdir", "^A-Za-z");
    print "<a href='browse.pl?dir=$escapeddir'>$partdir</a> / ";
    $incdir = $incdir . "$partdir/";
}

print "$file</p>\n";

print "<p><a class='file' href='oyster-gui.pl?vote=$mediadir/$file' target='curplay'>Vote for this song</a></p>\n";

if ($file =~ /mp3$/) {
    open (MP3, "id3v2 -l \"$rootdir$mediadir/$file\"|") or die $!;
    my @output = <MP3>;

    foreach my $line (@output) {
	print $line . "<br>";
    }

    close (MP3);

} elsif ($file =~ /ogg$/) {
    open (OGG, "ogginfo \"$rootdir$mediadir/$file\"|") or die $!;
    my @output = <OGG>;
    
    foreach my $line (@output) {
	print $line . "<br>";
    }

    close (OGG);
}

print end_html;
