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

print
    h1('Oyster'),
    strong("Now playing: <a href='fileinfo.pl?file=$info' target='browse'>$title</a>"),p,
    a({href=>'skip.sh'},'Skip'),p,
    a({href=>'oyster-gui.pl'},'Refresh'),p,
    a({href=>'stop.sh'},'Stop'),p,
    a({href=>'search.pl',-target=>'browse'},'Search'),
    end_html;

