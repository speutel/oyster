#!/usr/bin/perl

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

use oyster::conf;

my $savedir = `pwd`;
chomp($savedir);
my $conffile = "$savedir/oyster.conf";

%config = oyster::conf->get_config($conffile);
$basedir = $config{basedir};
my $mp3_player = "mpg321 -q";
my $ogg_player = "ogg123 -q";

my $pid = fork();

if ( ! $pid ) {

	open(FILENAME, "/tmp/oyster/kidplay");
	$file = <FILENAME>;
	close(FILENAME);
	
	$file =~ /.*\.([^\.]*$)/;
	$suffix = $1;

	chomp($suffix);
	chomp($file);

	if ( $suffix eq "mp3" ){
		$command = $mp3_player . ' ' . '"' . $file . '"';
		exec($command);
	} elsif ( ($suffix eq "ogg") ) {
		$command = $ogg_player . ' ' . '"' . $file . '"';
		#$command = $ogg_player . ' ' . '"' . $file . '" 2&>>' . $basedir . '/err';
		exec($command);
	} else {
		print STDERR "no player found for file $file";
	}

} else {

	open(PIDOUT, ">$basedir/player_pid");
	print PIDOUT "$pid\n";
	close(PIDOUT);

	waitpid($pid, 0);	

	open(CONTROL_OUT, ">$basedir/control");
	print CONTROL_OUT "done\n";
	close(CONTROL_OUT);

}
