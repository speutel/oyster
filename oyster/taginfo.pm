package oyster::taginfo;

use strict;
use warnings;
use oyster::conf;

my %tag;
my %CACHE;
my %config = oyster::conf->get_config('oyster.conf');
my $playlist = oyster::conf->get_playlist();

$ENV{LANG} = 'de_DE@euro';

my $VERSION = '1.0';

sub get_tag_light {

    my $filename = $_[1];

    dbmopen(%CACHE, "${config{'savedir'}}tagcache", 0644);
    if ($CACHE{$filename}) {
	$tag{'display'} = $CACHE{$filename};
    } else {
	%tag = get_tag('', $_[1]);
    }

    dbmclose(%CACHE);

    return $tag{'display'};

}

sub get_tag {
    %tag = ();

    $tag{'title'} = '';
    my $filename = $_[1];

    if ($filename =~ /mp3$/i) {
	$tag{'format'} = 'MP3';
	open (MP3, "id3v2 -l \"$filename\"|") or die $!;
	
	while (my $line = <MP3>) {
	    if ($line =~ /^Title/) {
		if ($line =~ /^Title\ \ \:\ (.*)Artist\:\ (.*)/) {
		    # id3v1                                                         
		    $tag{'title'} = $1;
		    $tag{'artist'} = $2;
		    $tag{'title'} =~ s/[\ ]*$//;
		    $tag{'artist'} =~ s/[\ ]*$//;
		} else {
		    # id3v2                                                 
		    $_ = $line;
		    ($tag{'title'}) = m/:\ (.*)$/;
		}
	    } elsif ($line =~ /^Lead/) {
		$_ = $line;
		($tag{'artist'}) = m/:\ (.*)$/;
	    } elsif ($line =~ /^Album\ \ \:\ (.*)Year\:\ ([0-9]*),\ Genre\:\ (.*)/) {
		$tag{'album'} = $1;
		$tag{'year'} = $2;
		$tag{'genre'} = $3;
		$tag{'album'} =~ s/[\ ]*$//;
		$tag{'genre'} =~ s/\ \(.*//;
	    } elsif ($line =~ /^Album\/Movie\/Show\ title\:\ (.*)/) {
		$tag{'album'} = $1;
	    } elsif ($line =~ /^Year\:\ ([0-9]*)/) {
		$tag{'year'} = $1;
	    } elsif ($line =~ /^Content\ type\:\ \([0-9]*\)(.*)/ ) {
		$tag{'genre'} = $1;
	    } elsif ($line =~ /^Comment.*Track\:\ ([0-9]*)/) {
		$tag{'track'} = $1;
	    } elsif ($line =~ /^Track\ number\/Position\ in\ set\:\ (.*)/) {
		$tag{'track'} = $1;
	    }
	}
	    
	close (MP3);
	
    } elsif ($filename =~ /ogg$/i) {
	$tag{'format'} = 'OGG Vorbis';
	open (OGG, "ogginfo \"$filename\"|") or die $!;
	
	while (my $line = <OGG>) {
	    $line =~ s/^\s*//;
	    $line =~ s/^TITLE=/title=/;
	    $line =~ s/^ARTIST=/artist=/;
	    $line =~ s/^ALBUM=/album=/;
	    $line =~ s/^DATE=/date=/;
	    $line =~ s/^TRACKNUMBER=/tracknumber=/;
	    $line =~ s/^COMMENT=/comment=/;
	    $line =~ s/^PLAYTIME=/playtime=/;
	    $line =~ s/^Playback\ length:/playtime=/;
	    if ($line =~ /title=(.*)/) {
		$tag{'title'} = $1;
	    } elsif ($line =~ /artist=(.*)/) {
		$tag{'artist'} = $1;
	    } elsif ($line =~ /album=(.*)/) {
		$tag{'album'} = $1;
	    } elsif ($line =~ /date=(.*)/) {
		$tag{'year'} = $1;
	    } elsif ($line =~ /genre=(.*)/) {
		$tag{'genre'} = $1;
	    } elsif ($line =~ /tracknumber=(.*)/) {
		$tag{'track'} = $1;
	    } elsif ($line =~ /comment=(.*)/) {
		$tag{'comment'} = $1;
	    } elsif ($line =~ /playtime=(.*)/) {
		$tag{'playtime'} = $1;
		$tag{'playtime'} =~ s/([0-9]*)[hms]/$1/g;
	    }
	}
    
	close (OGG);

    }

    # Count current score

    $tag{'score'} = 0;

    open (LASTVOTES, "${config{'savedir'}}lastvotes/$playlist");
    while (my $line = <LASTVOTES>) {
	chomp($line);
	$tag{'score'}++ if ($line eq $filename);
    }

    if ($tag{'title'} eq '') {
	$tag{'display'} = $filename;
	$tag{'display'} =~ s@.*/@@;
	$tag{'display'} =~ s/\.mp3//i;
	$tag{'display'} =~ s/\.ogg//i;
    } elsif ($tag{'artist'} eq '') {
	$tag{'display'} = $tag{'title'};
    } else {
	$tag{'display'} = "$tag{'artist'} - $tag{'title'}";
    }

    dbmopen(%CACHE, "${config{'savedir'}}tagcache", 0644);
    $CACHE{$filename} = $tag{'display'};
    dbmclose(%CACHE);    

    return %tag;
}
