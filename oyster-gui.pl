#!/usr/bin/perl
use CGI qw/:standard -no_xhtml/;
use URI::Escape;
use strict;

open(INFO, "/tmp/oyster/info");
my $info = <INFO>;
chomp($info);
$info =~ s/^np:\ //;
close(INFO);

my ($title, $artist) = "";

print
    header,
    start_html(-title=>'Oyster-GUI',
	       -style=>{'src'=>'layout.css'},
	       -head=>CGI::meta({-http_equiv => 'Content-Type',
				 -content    => 'text/html; charset=iso-8859-1'}));

print "<meta http-equiv='refresh' content='30; URL=oyster-gui.pl'>";

if ($info =~ /mp3$/) {
    open (MP3, "id3v2 -l \"$info\"|") or die $!;
    my @output = <MP3>;

    foreach my $line (@output) {
	if ($line =~ /^Title/) {
	    $_ = $line;
	    if ($line =~ /^Title\ \ \:.*Artist/) {
		# id3v1
		($title,$artist) = m/^Title\ \ \:\ (.*)Artist\:\ (.*)/;
		$title =~ s/[\ ]*$//;
	    } else {
		# id3v2
		($title) = m/:\ (.*)$/;
	    }
	} elsif ($line =~ /^Lead/) {
	    $_ = $line;
	    ($artist) = m/:\ (.*)$/;
	}
    }	

    close (MP3);

} elsif ($info =~ /ogg$/) {
    open (OGG, "ogginfo \"$info\"|") or die $!;
    my @output = <OGG>;
    
    foreach my $line (@output) {
	$line =~ s/^\w*//;
	$line =~ s/TITLE=/title=/;
	$line =~ s/ARTIST=/artist=/;
	if ($line =~ /title=/) {
	    $_ = $line;
	    ($title) = m/title=(.*)/;
	} elsif ($line =~ /artist=/) {
	    $_ = $line;
	    ($artist) = m/artist=(.*)/;
	}
    }

    close (OGG);
    
}



if ($title eq "") {
    $title = $info;
    $title =~ s@.*/@@;
    $title =~ s/\.mp3//;
    $title =~ s/\.ogg//;
} else {
    $title = "$artist - $title";
}

$info = uri_escape("$info", "^A-Za-z");

print h1('Oyster');
print "<table width='100%'>";
print "<tr><td><strong>Now playing: <a href='fileinfo.pl?file=$info' target='browse'>$title</a></strong></td>";
print "<td><a href='oyster-gui.pl'>Refresh</a></td></tr>";
print "</table>";

print end_html;

