#!/usr/bin/perl

# $basedir is where oyster puts all it's runtime-files.
# It will be deleted after oyster has quit.
my $basedir = "/tmp/oyster";
my (@filelist, $file, $control, $file_override);
my $fifo="false";


init();

while ( 1 ) {
	main();
}

#cleaning up our files
unlink <$basedir/*>;
rmdir "$basedir";

#because of some obscure error this use-statement does not work when 
#I put it in the beginning of the file
use Switch 'Perl5', 'Perl6';






#########################
## defining procedures ##
#########################

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
	switch ($control) {

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
	open (STDERR, ">>$basedir/err");
	open (STDOUT, ">>/dev/null");
	srand;
	
	@filelist = <FILELIST>;
	
	mkdir($basedir);	
	print STDERR "making fifos...";
	system("/usr/bin/mkfifo /tmp/oyster/control");
	system("/usr/bin/mkfifo /tmp/oyster/kidplay");
	print STDERR " done\n";

}


sub choose_file {

	print STDERR $file;
	
	if ( $file_override eq "true") {
		#don't touch $file
		$file_override = "false";
	} elsif ( -e "$basedir/votes" ) {
		$file = evaluate_votes();
	} elsif ( -e "$basedir/playnext" ) {
		open( FILEIN, "$basedir/playnext" );
		$file = <FILEIN>;
		close( FILEIN );
		unlink "$basedir/playnext";
	} else {
		$index = rand @filelist;
		$file = $filelist[$index];
	}
}


sub evaluate_votes {
	#Does nothing yet
}

sub info_out {
	
	open(INFO, ">$basedir/info");
	print INFO "np: " . $file;
	close(INFO);
	print STDERR "info_out zuende\n";
	
}
