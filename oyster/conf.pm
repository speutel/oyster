# oyster - a perl-based jukebox and web-frontend
#
# Copyright (C) 2004 Benjamin Hanzelmann <ben@nabcos.de>, Stepan Windmüller <windy@white-hawk.de>, Stefan Naujokat <git@ethric.de>
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

package oyster::conf;

use strict;
use warnings;

my %config;

my $VERSION = '1.0';
	
sub get_config {
	my $conffile = $_[1];

	open(CONF, $conffile) || die $!;
	
	while ( my $line = <CONF> ) {
		if ( $line =~ /^[a-z]/ ) {
		    chomp($line);
		    my ($key, $value) = split("=", $line);
		    if (($key eq 'mediadir') || ($key eq 'basedir') || ($key eq 'savedir')) {
					$value =~ s/\/$//;
					$value .= '/';
		    }
		    $config{$key} = $value;
		}
	}

	close(CONF);

	return %config;
}

sub get_playlist {

    my %config = get_config('','oyster.conf');
    my $playlist = 'default';

    if (-e "${config{basedir}}playlist") {
	open (PLAYLIST, "${config{basedir}}playlist");
	$playlist = <PLAYLIST>;
	close PLAYLIST;

	chomp($playlist);
    }
    return $playlist;
}

sub rel_to_abs {
		my $path = $_[1];
		my $dir = $_[2];
		print "path: $path, dir: $dir\n";
		
		if ( ! ($path =~ /^\//) ) {
			$path = $dir . $path;
		}

		print $path . "\n";
		
		$path =~ s@[^/]*/\.\./@@g;

		return $path;	
	
}
