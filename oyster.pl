#!/usr/bin/perl

my $basedir = "/tmp/oyster";
my (@filelist, $file, $control, $file_override);
my $fifo="false";


init();
while ( 1 ) {
	main();
}
unlink </tmp/oyster/*>;
rmdir "/tmp/oyster";

use Switch 'Perl5', 'Perl6';


###################


sub main {
		
	choose_file();
	info_out();
	play_file();
	get_control();
	interpret_control($control);
	
}


sub get_control {
	
	#CONTROL ist eine named pipe, open blockt!
	open(CONTROL, "$basedir/control");
	$control = <CONTROL>;
	close(CONTROL);

}


sub play_file {

	system("./play.pl &");
	
	open(KIDPLAY, ">/tmp/oyster/kidplay");
	print KIDPLAY "$file\n";
	close(KIDPLAY);

}


sub interpret_control {
	$sw = $control;
	switch ($sw) {

		case /^next/	{ 
			system("killall play.pl mpg321 ogg123"); 
		}
		case /^done/ { 
		}
		case /^F\ / {
			$control =~ /^F\ (.*)$/;
			$file = $1;
			$file_override = "true";
			system("killall play.pl mpg321 ogg123");
		}	
		case /^quit/	{ system("killall play.pl mpg321 ogg123"); exit; }
	}
}


sub init {

	open (FILELIST, $ARGV[0]);
	system("/usr/bin/mkfifo /tmp/oyster/control");
	system("/usr/bin/mkfifo /tmp/oyster/kidplay");
	open (STDERR, ">>/tmp/oyster/err");
	open (STDOUT, ">>/dev/null");
	srand;
	
	@filelist = <FILELIST>;
	
	mkdir($basedir);	
	open(INFO, ">$basedir/info");

}


sub choose_file {

	print STDERR $file;
	
	if ( $file_override eq "true") {
		#don't touch $file
		$file_override = "false";
	} else {
		$index = rand @filelist;
		$file = $filelist[$index];
	}
	print STDERR $file;
}


sub info_out {
	
	print INFO "np: " . $file;
	print STDERR "info_out zuende\n";
}
