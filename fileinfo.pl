#!/usr/bin/perl
use CGI qw/:standard/;

print header, start_html(-title=>'Oyster-GUI',-style=>{'src'=>'layout.css'});

my $basedir = '/Multimedia/Audio/';
my $rootdir=$basedir;

if (param()) {
    $basedir = param('file');
    $basedir =~ s@//$@/@;
    $basedir =~ s/\.\.\///g;
    $basedir = $rootdir if (($basedir eq "..") || ($basedir eq ""));
    $file = $basedir;
    $basedir =~ s/\/[^\/]*$//;
    $file =~ s/.*\///;
    $basedir = $rootdir if (($basedir eq "..") || ($basedir eq ""));
}

$basedir = $rootdir if (!($basedir =~ /^\Q$rootdir\E/));

print "<a href='browse.pl?dir=$basedir'>$basedir</a><br><br>";

if ($file =~ /mp3$/) {
    open (MP3, "id3v2 -l \"$basedir/$file\"|") or die $!;
    my @output = <MP3>;

    foreach my $line (@output) {
	print $line . "<br>";
    }

    close (MP3);

} elsif ($file =~ /ogg$/) {
    open (OGG, "ogginfo \"$basedir/$file\"|") or die $!;
    my @output = <OGG>;
    
    foreach my $line (@output) {
	print $line . "<br>";
    }

    close (OGG);
}

print end_html;
