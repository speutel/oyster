#!/usr/bin/perl
use CGI qw/:standard/;
use URI::Escape;

open(INFO, "/tmp/oyster/info");
$info = <INFO>;
chomp($info);
$info =~ s/^np:\ //;
close(INFO);

my ($title, $artist) = "";

print header, start_html(-title=>'Oyster-GUI',-style=>{'src'=>'layout.css'});;

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

print "<br><br>";

print "<table width='100%'>";
print "<tr><td align='center' width='30%'><a href='start.sh'>Start</a></td>";
print "<td align='center' width='40%'><a href='skip.sh'>Skip</a></td>";
print "<td align='center' width='30%'><a href='stop.sh'>Stop</a></td>";
print "</tr></table>\n";

my $volume = `aumix -w q`;
$volume =~ s/^pcm\ //;
$volume =~ s/,.*//;

print "<table width='100%'>";
print "<tr><td align='center' width='40%'><a href='volume.pl?vol=down'>Volume Down</a></td>";
print "<td align='center' width='20%'><a href='volume.pl?vol=50'>$volume</a></td>";
print "<td align='center' width='40%'><a href='volume.pl?vol=up'>Volume Up</a></td>";
print "</tr></table>\n";

print end_html;

