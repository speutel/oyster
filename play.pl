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

	#open(OUT, ">/tmp/other");
	#print OUT "I am the other!\n";
	
	open(FILENAME, "/tmp/oyster/kidplay");
	$file = <FILENAME>;
	close(FILENAME);
	$file =~ /.*\.([^\.]*$)/;

	#print OUT "got $file";

	$suffix = $1;
	chomp($suffix);
	chomp($file);

	if ( $suffix eq "mp3" ){
 	 $command = $mp3_player . ' ' . '"' . $file . '"';
	}
	elsif ( ($suffix eq "ogg") ) {
 	 $command = $ogg_player . ' ' . '"' . $file . '"';
	} else {
		print STDERR "Something went wrong with $file\n";
		#	print OUT "Something went wrong with $file\n";
	}
	
	#print OUT "$command\n";
	close(OUT);
	exec($command);

} else {
	open(PIDOUT, ">$basedir/player_pid");
	print PIDOUT "$pid\n";
	close(PIDOUT);

	waitpid($pid, 0);	
	
	open(CONTROL_OUT, ">$basedir/control");
	print CONTROL_OUT "done\n";
	close(CONTROL_OUT);

}
