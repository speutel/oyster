package oyster::taginfo;

use strict;
use warnings;

my %tag;

my $VERSION = '1.0';

sub get_tag {
    %tag = ();
    my $filename = $_[1];

    if ($filename =~ /mp3$/i) {
	$tag{'format'} = 'MP3';
	open (MP3, "id3v2 -l \"$filename\"|") or die $!;
	
	while (my $line = <MP3>) {
	    if ($line =~ /^Title/) {
		$_ = $line;
		if ($line =~ /^Title\ \ \:.*Artist/) {
		    # id3v1                                                         
		    ($tag{'title'},$tag{'artist'}) = m/^Title\ \ \:\ (.*)Artist\:\ (.*)/;
		    $tag{'title'} =~ s/[\ ]*$//;
		} else {
		    # id3v2                                                 
		    ($tag{'title'}) = m/:\ (.*)$/;
		}
	    } elsif ($line =~ /^Lead/) {
		$_ = $line;
		($tag{'artist'}) = m/:\ (.*)$/;
	    } elsif ($line =~ /^Album/) {
		$_ = $line;
		($tag{'album'}, $tag{'year'}, $tag{'genre'}) = m@Album\ \ \:\ (.*)Year\:\ ([0-9]*),\ Genre\:\ (.*)\(@;
		$tag{'album'} =~ s/[\ ]*$//;
	    }
	}
	    
	close (MP3);
	
    } elsif ($filename =~ /ogg$/i) {
	$tag{'format'} = 'OGG Vorbis';
	open (OGG, "ogginfo \"$filename\"|") or die $!;
	
	while (my $line = <OGG>) {
	    $line =~ s/^\s*//;
	    $line =~ s/TITLE=/title=/;
	    $line =~ s/ARTIST=/artist=/;
	    $line =~ s/ALBUM=/date=/;
	    $line =~ s/DATE=/date=/;
	    $_ = $line;
	    if ($line =~ /title=/) {
		($tag{'title'}) = m/title=(.*)/;
	    } elsif ($line =~ /artist=/) {
		($tag{'artist'}) = m/artist=(.*)/;
	    } elsif ($line =~ /album=/) {
		($tag{'album'}) = m/album=(.*)/;
	    } elsif ($line =~ /date=/) {
		($tag{'year'}) = m/date=(.*)/;
	    } elsif ($line =~ /genre=/) {
		($tag{'genre'}) = m/genre=(.*)/;
	    }
	}
    
	close (OGG);

    }

    if ($tag{'title'} eq "") {
	$tag{'display'} = $filename;
	$tag{'display'} =~ s@.*/@@;
	$tag{'display'} =~ s/\.mp3//i;
	$tag{'display'} =~ s/\.ogg//i;
    } else {
	$tag{'display'} = "$tag{'artist'} - $tag{'title'}";
    }

    return %tag;
}
