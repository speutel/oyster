#!/usr/bin/perl

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
		$command = $mp3_player . ' ' . '"' . $file . '" 2&>>' . $basedir . '/err';
		exec($command);
	} elsif ( ($suffix eq "ogg") ) {
		$command = $ogg_player . ' ' . '"' . $file . '" 2&>>' . $basedir . '/err';
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
