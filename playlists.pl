#!/usr/bin/perl
use CGI qw/:standard -no_xhtml/;
use URI::Escape;
use strict;
use oyster::conf;
use oyster::common;

my %config = oyster::conf->get_config('oyster.conf');
my $playlist = oyster::conf->get_playlist();
my $savedir = $config{'savedir'};

oyster::common->navigation_header();

my $globdir = "${savedir}lists/";
my @entries = <$globdir*>;

my @files = ();

foreach my $entry (@entries) {
    if (-f "$entry") {
	$entry =~ s/$globdir//;
	push (@files, "$entry");
    }
}

print "<table width='100%'>";

foreach my $file (@files) {
    print "<tr><td>$file</td><td><a href='oyster-gui.pl?action=loadlist&amp;file=$file' target='curplay'>Load List</a></td>";
}

print "</table>";

print end_html;
