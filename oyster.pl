#!/usr/bin/perl

# commandline parameters:
# only parameter is a file with a list of musicfiles to choose from randomly.

# $basedir is where oyster puts all it's runtime-files.
# It will be deleted after oyster has quit.
my $basedir = "/tmp/oyster";
my $savedir = ".";

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
	interpret_control();
	
}


sub get_control {
	# get control-string from control-FIFO
	
	#CONTROL ist eine named pipe, open blockt!
	open(CONTROL, "$basedir/control");
	$control = <CONTROL>;
	close(CONTROL);

}


sub play_file {
	# start play.pl and tell it which file to play
	
	system("./play.pl &");
	
	open(KIDPLAY, ">/tmp/oyster/kidplay");
	print KIDPLAY "$file\n";
	close(KIDPLAY);

}


sub interpret_control {
	# find out what to do by checking $control

	## TODO: Listenverwaltung: 
	#"L $listname" fürs Laden einer Liste, 
	#"S $listname" fürs speichern, 
	#"LISTS" fürs Auflisten aller gespeicherten, 
	#"NEW $name" für das Erstellen einer neuen Liste (Einträge zeilenweise über das FIFO lesen).
	
	## TODO: Voteverwaltung
	#"V $votefile"

	
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
		case /^quit/	{ 
			system("killall play.pl mpg321 ogg123"); 
			exit; 
		}
		case /^S\ / {
			$control =~ /^S\ (.*)$/;
			save_list($1);
		}
		case /^L\ / {
			$control =~ /^L\ (.*)$/;
			load_list($1);
		}
		case /^N\ / {
			$control =~ /^NEWLIST/;
			get_list();
		}
		case /^LISTS/ {
			# lists filelists into the FIFO
		}
		else {
			get_control();
			interpret_control();
		}

			
	}
}

sub load_list {
	# $_[0] ist Name der Liste
	
	$listname = $_[0];
	$list_dir = "$savedir/lists";

	open(LISTIN, "$list_dir/$listname");
	@filelist = <LISTIN>;
	close(LISTIN);

	get_control();
	interpret_control();
}

sub save_list {
	# $_[0] ist Name der Liste
	
	$listname = $_[0];
	$list_dir = "$savedir/lists";

	if ( ! -d $list_dir ) {
		print STDERR "list_dir is no directory!\n";
		if ( -e $list_dir ) {
			unlink($list_dir);
		}
		mkdir($list_dir);
	}

	open(LISTOUT, ">$list_dir/$listname");
	print LISTOUT @filelist;
	close(LISTOUT);

	get_control();
	interpret_control();
	
}

sub get_list {
	
	#CONTROL ist eine named pipe, open blockt!
	open(CONTROL, "$basedir/control");
	@filelist = <CONTROL>;
	close(CONTROL);

	get_control();
	interpret_control();
}

sub init {
	# well, it's called "init". guess.
	
	
	# open filelist and read it into memory
	open (FILELIST, $ARGV[0]);
	@filelist = <FILELIST>;

	# tell STDERR and STDOUT where they can dump their messages
	open (STDERR, ">>$basedir/err");
	open (STDOUT, ">>/dev/null");
	
	# initialize random
	srand;
	
	# setup $basedir, make fifos
	mkdir($basedir);	
	system("/usr/bin/mkfifo /tmp/oyster/control");
	system("/usr/bin/mkfifo /tmp/oyster/kidplay");

}


sub choose_file {

	
	if ( $file_override eq "true") {
		#don't touch $file
		$file_override = "false";
	} elsif ( -e "$basedir/playnext" ) {
		open( FILEIN, "$basedir/playnext" );
		$file = <FILEIN>;
		close( FILEIN );
		unlink "$basedir/playnext";
	} else {
		$index = rand @filelist;
		$file = $filelist[$index];
		if ( -e "$savedir/blacklist" ) {
			print STDERR "Blacklist existiert.\n";
			open(BLACKLIST, "$savedir/blacklist");
			while( $regexp = <BLACKLIST> ) {
				print STDERR "File : $file regexp: $regexp\n";
				if ( $file =~ /\Q$regexp/ ) {
					choose_file();
				}
			}
		}	
	}
}


sub info_out {
	
	open(INFO, ">$basedir/info");
	print INFO "np: " . $file;
	close(INFO);
	print STDERR "info_out zuende\n";
	
}
