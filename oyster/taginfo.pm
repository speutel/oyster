# oyster - a perl-based jukebox and web-frontend
#
# Copyright (C) 2004 Benjamin Hanzelmann <ben@nabcos.de>, Stephan Windmüller <windy@white-hawk.de>, Stefan Naujokat <git@ethric.de>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

package oyster::taginfo;

use strict;
use warnings;
use oyster::conf;
use oyster::common;

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
	get_mp3_tags($filename);
    } elsif ($filename =~ /ogg$/i) {
	get_ogg_tags($filename);
    }
    
    # Count current score

    $tag{'score'} = 0;

    get_score($filename);

	set_display($filename);

    dbmopen(%CACHE, "${config{'savedir'}}tagcache", 0644);
    $CACHE{$filename} = $tag{'display'};
    dbmclose(%CACHE);    

    return %tag;
}

sub set_display {
    my $filename = $_[0];
    
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
}

sub get_score {
    my $filename = $_[0];
    my $scorefile = "${config{'savedir'}}scores/$playlist";

    if(-f $scorefile ) {
	open (LASTVOTES, "${config{'savedir'}}scores/$playlist");
	while (my $line = <LASTVOTES>) {
	    chomp($line);
	    $tag{'score'}++ if ($line eq $filename);
	}
    } else {
	$tag{'score'} += 0;
    }    
}

sub get_mp3_tags {
    my $filename = $_[0];
    
    $tag{'format'} = 'MP3';
    open (MP3, "id3v2 -R \"$filename\"|") or die $!;
	
    while (my $line = <MP3>) {
	if ($line =~ /^Title/) {
	    if ($line =~ /^Title\ \ \:\ (.*)Artist\:\ (.*)/) {
		# id3v1                                                         
		$tag{'title'} = oyster::common->remove_html($1);
		$tag{'artist'} = oyster::common->remove_html($2);
		$tag{'title'} =~ s/[\ ]*$//;
		$tag{'artist'} =~ s/[\ ]*$//;
	    } else {
		# id3v2, old version
		$_ = oyster::common->remove_html($line);
		($tag{'title'}) = m/:\ (.*)$/;
	    }
	} elsif ($line =~ /^TIT2\ \(.*\)\:\ (.*)$/) {
	    $tag{'title'} = oyster::common->remove_html($1);
	} elsif ($line =~ /^Lead/) {
	    $tag{'artist'} = oyster::common->remove_html($1);
	} elsif ($line =~ /^TPE1\ \(.*\)\:\ (.*)$/) {
	    $_ = oyster::common->remove_html($line);
	    $tag{'artist'} = oyster::common->remove_html($1);
	} elsif ($line =~ /^Album\ \ \:\ (.*)Year\:\ ([0-9]*),\ Genre\:\ (.*)/) {
	    $tag{'album'} = oyster::common->remove_html($1);
	    $tag{'year'} = oyster::common->remove_html($2);
	    $tag{'genre'} = oyster::common->remove_html($3);
	    $tag{'album'} =~ s/[\ ]*$//;
	    $tag{'genre'} =~ s/\ \(.*//;
	} elsif ($line =~ /^Album\/Movie\/Show\ title\:\ (.*)/) {
	    $tag{'album'} = oyster::common->remove_html($1);
	} elsif ($line =~ /^TALB\ \(.*\)\:\ (.*)$/) {
	    $tag{'album'} = oyster::common->remove_html($1);
	} elsif ($line =~ /^Year\:\ ([0-9]*)/) {
	    $tag{'year'} = oyster::common->remove_html($1);
	} elsif ($line =~ /^TYER\ \(Year\)\:\ (.*)$/) {
	    $tag{'year'} = oyster::common->remove_html($1);
	} elsif ($line =~ /^Content\ type\:\ \([0-9]*\)(.*)/ ) {
	    $tag{'genre'} = oyster::common->remove_html($1);
	} elsif ($line =~ /^TCON\ \(.*\)\:\ (.*)\ \([0-9]*\)$$/) {
	    $tag{'genre'} = oyster::common->remove_html($1);
	} elsif ($line =~ /^Comment.*Track\:\ ([0-9]*)/) {
	    $tag{'track'} = oyster::common->remove_html($1);
	} elsif ($line =~ /^Track\ number\/Position\ in\ set\:\ (.*)/) {
	    $tag{'track'} = oyster::common->remove_html($1);
	} elsif ($line =~ /^TRCK\ \(.*\)\:\ (.*)$/) {
	    $tag{'track'} = oyster::common->remove_html($1);
	}
    }
	    
    close (MP3);
}	
    

sub get_ogg_tags {
    my $filename = $_[0];
	
    $tag{'format'} = 'OGG Vorbis';
    open (OGG, "ogginfo \"$filename\"|") or die $!;
	
    while (my $line = <OGG>) {
	$line =~ s/^\s*//;
	if ($line =~ /title=(.*)/i) {
	    $tag{'title'} = oyster::common->remove_html($1);
	} elsif ($line =~ /artist=(.*)/i) {
	    $tag{'artist'} = oyster::common->remove_html($1);
	} elsif ($line =~ /album=(.*)/i) {
	    $tag{'album'} = oyster::common->remove_html($1);
	} elsif ($line =~ /date=(.*)/i) {
	    $tag{'year'} = oyster::common->remove_html($1);
	} elsif ($line =~ /genre=(.*)/i) {
	    $tag{'genre'} = oyster::common->remove_html($1);
	} elsif ($line =~ /tracknumber=(.*)/i) {
	    $tag{'track'} = oyster::common->remove_html($1);
	} elsif ($line =~ /comment=(.*)/i) {
	    $tag{'comment'} = oyster::common->remove_html($1);
	} elsif ($line =~ /playback\ length=(.*)/i) {
	    $tag{'playtime'} = oyster::common->remove_html($1);
	    $tag{'playtime'} =~ s/([0-9]*)[hms]/$1/g;
	}
    }
    close (OGG);
}
