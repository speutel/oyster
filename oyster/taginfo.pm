package oyster::taginfo;

use strict;
use warnings;

my %tag;

my $VERSION = '1.0';
	
sub get_tag {
    my $filename = $_[1];
    my ($title, $artist, $album, $year, $genre, $display) = "";

    if ($filename =~ /mp3$/i) {
	open (MP3, "id3v2 -l \"$filename\"|") or die $!;
	
	while (my $line = <MP3>) {
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
	    } elsif ($line =~ /^Album/) {
		$_ = $line;
		($album, $year, $genre) = m@Album\ \ \:\ (.*)Year\:\ ([0-9]*),\ Genre\:\ (.*)@;
		$album =~ s/[\ ]*$//;
	    }
	}
	    
	close (MP3);
	
    } elsif ($filename =~ /ogg$/i) {
	open (OGG, "ogginfo \"$filename\"|") or die $!;
	
	while (my $line = <OGG>) {
	    $line =~ s/^\s*//;
	    $line =~ s/TITLE=/title=/;
	    $line =~ s/ARTIST=/artist=/;
	    $line =~ s/ALBUM=/date=/;
	    $line =~ s/DATE=/date=/;
	    $_ = $line;
	    if ($line =~ /title=/) {
		($title) = m/title=(.*)/;
	    } elsif ($line =~ /artist=/) {
		($artist) = m/artist=(.*)/;
	    } elsif ($line =~ /album=/) {
		($album) = m/album=(.*)/;
	    } elsif ($line =~ /date=/) {
		($year) = m/date=(.*)/;
	    } elsif ($line =~ /genre=/) {
		($genre) = m/genre=(.*)/;
	    }
	}
    
	close (OGG);

    }

    if ($title eq "") {
	$display = $filename;
	$display =~ s@.*/@@;
	$display =~ s/\.mp3//i;
	$display =~ s/\.ogg//i;
    } else {
	$display = "$artist - $title";
    }

    $tag{'artist'} = $artist;
    $tag{'title'} = $title;
    $tag{'display'} = $display;
    $tag{'album'} = $album;
    $tag{'year'} = $year;
    $tag{'genre'} = $genre;
    return %tag;
}
