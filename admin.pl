#!/usr/bin/perl
# oyster - a perl-based jukebox and web-frontend
#
# Copyright (C) 2004 Benjamin Hanzelmann <ben@nabcos.de>,
#  Stephan Windmüller <windy@white-hawk.de>,
#  Stefan Naujokat <git@ethric.de>
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

use CGI qw/:standard -no_xhtml/;
use strict;
use oyster::conf;

my @knownoptions = (
		    'basedir',
		    'savedir',
		    'mediadir',
		    'theme',
		    'maxscored',
		    'voteplay',
		    'coverfilenames',
		    'coverwidth'
		    );

# Set options

if (param('action') && (param('action') eq 'set')) {
    open (CONFFILE, 'oyster.conf');
    open (TMPFILE, '>oyster.conf.tmp') or die $!;
    while (my $line = <CONFFILE>) {
	my $isoption = 0;
	foreach my $option (@knownoptions) {
	    if ($line =~ /^\Q$option\E/) {
		print TMPFILE "$option=" . param($option) . "\n";
		$isoption = 1;
	    }
	}
	if (! $isoption) {
	    print TMPFILE $line;
	}
    }
    close (TMPFILE);
    close (CONFFILE);
    unlink ('oyster.conf');
    rename 'oyster.conf.tmp', 'oyster.conf';
}

# Get current options

my %currentvalue = ();
my %config = oyster::conf->get_config('oyster.conf');

foreach my $option (@knownoptions) {
    if ($config{$option}) {
	$currentvalue{$option} = $config{$option};
    } else {
	$currentvalue{$option} = '';
    }
}

# Get available Themes

my @themes = ();
my @dirs = <$config{'savedir'}/themes/*>;
foreach my $theme (@dirs) {
    $theme =~ s/^.*\///;
    push (@themes, $theme);
}


# Print form with current values

print
    header,
    start_html(-title=>'Oyster-GUI',
	       -style=>{'src'=>"themes/${config{'theme'}}/layout.css"},
	       -head=>CGI::meta({-http_equiv => 'Content-Type',
				 -content    => 'text/html; charset=iso-8859-1'}));

print h1('Oyster Admin Interface');

print start_form;

print hidden('action','set');

print h2('Basedir');
print textfield(-name=>'basedir',
		-default=>$currentvalue{'basedir'},
		-size=>50,
		-maxlength=>255);

print p({class=>'configdescription'},
	'Basedir tells oyster where it should put its dynamic files, ' . 
	'the FIFOs it needs and the log and infofile.'
	);

print h2('Savedir');
print textfield(-name=>'savedir',
		-default=>$currentvalue{'savedir'},
		-size=>50,
		-maxlength=>255);

print p({class=>'configdescription'},
	'Savedir tells oyster where to save files that it needs for ' .
	'more than one session, for example the votes you did and ' .
	'the playlists you save'
	);

print h2('Mediadir');
print textfield(-name=>'mediadir',
		-default=>$currentvalue{'mediadir'},
		-size=>50,
		-maxlength=>255);

print p({class=>'configdescription'},
	'mediadir is where your files are. ' .
	'If you don\'t give oyster a playlist in the commandline, ' .
	'it will search your files under this directory and build a ' .
	'default playlist from these.'
	);

		 
print h2('Max Scored');
print textfield(-name=>'maxscored',
		-default=>$currentvalue{'maxscored'},
		-size=>8,
		-maxlength=>8);

print p({class=>'configdescription'},
	'Max Scored sets the maximum number of saved votes ' .
	'(oyster chooses songs at random from this list)'
	);

print h2('Voteplay');
print textfield(-name=>'voteplay',
		-default=>$currentvalue{'voteplay'},
		-size=>3,
		-maxlength=>3);

print p({class=>'configdescription'},
	'voteplay sets the probability in percent that one '  .
	'of the files from lastvotes is played.'
	);

print h2('Theme');
print popup_menu(-name=>'theme',
		 -values=>\@themes,
		 -default=>$currentvalue{'theme'});

print p({class=>'configdescription'},
	'Choose here which theme oyster uses.'
	);

print h2('Cover Filenames');
print textfield(-name=>'coverfilenames',
		-default=>$currentvalue{'coverfilenames'},
		-size=>50,
		-maxlength=>255);

print p({class=>'configdescription'},
	'Cover Filenames is a comma-seperated list, which lists ' .
	'all possible names for album-covers relative to the album. ' .
	'Use ${album} to reference in filenames and ${albumus} if ' .
	'you like to use underscores instead of whitespaces'
	);

print h2('Coverwidth');
print textfield(-name=>'coverwidth',
		-default=>$currentvalue{'coverwidth'},
		-size=>3,
		-maxlength=>4);

print p({class=>'configdescription'},
	'coverwidth is the width of the cover displayed in ' .
	'File Information'
	);


print submit(value=>'Save settings');
print " " . reset,end_form;

print end_html;
