#!/usr/bin/perl

use strict;

my $basedir = "/tmp/oyster";
my $mp3_player = "mpg123";
my $ogg_player = "ogg123";
my @filelist, $file, $control;




init();
while ( true ) {
	main();
}



###################


sub main {
		
	$pid = open(KID_PLAY, "|-");
	
	if (! $pid) {
		$file = <STDIN>;	
		play($file);
	} else {
		choose_file();
		info_out();
		
		print KID_PLAY "$file/n";
		
		#CONTROL ist eine named pipe, open blockt!
		open(CONTROL, "$basedir/control");
		$control = <CONTROL>;
		close(CONTROL);

	}

}


sub init {

	open (FILELIST, $ARGV[0]);
	
	srand;
	
	@filelist = <FILELIST>;
	
	mkdir $basedir;	
	open(INFO, ">$basedir/info");

}


sub choose_file {

	$index = rand @filelist;
	$file = $filelist[$index];

}


sub play {
	
	$file =~ /.*\.([^\.]*$)/
	
	$suffix = $1;

	if ( ($suffix eq "mp3") | ($suffix eq "MP3") ) {
		$real_player = $mp3_player;
	}
	elsif ( ($suffix eq "ogg") | ($suffix eq "OGG") ) {
		$real_player = $ogg_player;
	}

	system ($real_player $file);
	

	#CONTROL_OUT ist eine named pipe! open blockt!
	open(CONTROL_OUT, ">$basedir/control");
	print CONTROL_OUT "next\n";
	close(CONTROL_OUT);
	
	exit;
}


sub info_out {
	
	print INFO "np: " . $file;

}
