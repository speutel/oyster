#!/usr/bin/perl

# commandline parameters:
# only parameter is a file with a list of musicfiles to choose from randomly.

# $basedir is where oyster puts all it's runtime-files.
# It will be deleted after oyster has quit.
my $basedir = "/tmp/oyster";
my $savedir = ".";
my $list_dir = "$savedir/lists";

my ($lastvotes_pointer, @lastvotes, $lastvotes_file);
my (@filelist, $file, $control, %votelist);
my ($file_override); 
#use warnings;

init();

while ( 1 ) {
	main();
}


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

	switch ($control) {
		
		case /^next/	{ 
			system("killall play.pl mpg321 ogg123"); 
		}
		case /^done/ { 
		}
		case /^F\ / {
			$control =~ s/\\//g;
			$control =~ /^F\ (.*)$/;
			$file = $1;
			$file_override = "true";
			system("killall play.pl mpg321 ogg123");
		}	
		case /^quit/	{ 
			system("killall play.pl mpg321 ogg123"); 
			cleanup();
			exit; 
		}
		case /^S\ / {
			$control =~ /^S\ (.*)$/;
			save_list($1);
			get_control();
			interpret_control();
		}
		case /^L\ / {
			$control =~ /^L\ (.*)$/;
			load_list($1);
			get_control();
			interpret_control();
		}
		case /^NEWLIST/ {
			get_list();
			get_control();
			interpret_control();
		}
		case /^P/ {
			$control =~ /^P\ (.*)$/;
			open(CONTROL, "$basedir/control");
			if ( ! $1 ) {
				print CONTROL @filelist;
			} else {
				open(LIST, "$savedir/lists/$1") || print CONTROL "No such list!\n" && next;
				@files = <LIST>;
				print CONTROL @files;
			}
			close(CONTROL);
		}
		case /^LISTS/ {
			# lists filelists into the FIFO
			open(CONTROL, ">$basedir/control");
			@lists = <./lists/*>;
			foreach $list ( @lists ) {
				print CONTROL $list . "\n";
			}
			close(CONTROL);
			get_control();
			interpret_control();
		}
		case /^V\ / {
			$control =~ s/\\//g;
			$control =~ /^V\ (.*)$/;
			process_vote($1);
			get_control();
			interpret_control();
		}
		else {
			get_control();
			interpret_control();
		}
	}
}

sub process_vote {
	## FIXME test this!
	my $voted_file = $_[0];
	
	print STDERR "voted for $voted_file\n";
	
	my $winner = "";
	my $max_votes = 0;
	
	if ( $voted_file ne "") {
		if ( $votelist{$voted_file} ne "" ) {
			$votelist{$voted_file} += 1;
		} else { 
			$votelist{$voted_file} = 1;
		}
	$lastvotes_pointer = ++$lastvotes_pointer % 30;
	$lastvotes[$lastvotes_pointer] = $voted_file . "\n";
	}
	
	foreach $key (keys %votelist) { 
		if ($votelist{$key} > $max_votes) {
			$winner = $key; $max_votes = $votelist{$key};
		}
	}
	
	if ($votelist{$winner} > 0) {
		print STDERR "winner is $winner\n";
	
		open(PLAYNEXT, ">$basedir/playnext") || die $!;
		print PLAYNEXT $winner . "\n";
		close(PLAYNEXT);
	}
	
	# @lastvotes is an array which holds the recent 30 votes.
	# &choose_file will choose a file from this array with a given probability.
	# It will then choose one entry from this array, and there may be double 
	# file-entries (if you vote one file more than once
	# in 30 votes, for example ;). Yes, that means if you vote for one file more
	# than once, the probability for it to be played in random play is higher than 
	# for a file that got voted once in the last 30 votes.
}

sub cleanup {

	## save permanent data
	# save lastvotes-list
	open(LASTVOTES, ">$lastvotes_file");
	print LASTVOTES $lastvotes_pointer . "\n";
	foreach $entry ( @lastvotes ) {
		print LASTVOTES $entry;
	}
	close(LASTVOTES);
	
	#cleaning up our files
	unlink <$basedir/*>;
	rmdir "$basedir";

}

sub load_list {
	
	$listname = $_[0];

	open(LISTIN, "$list_dir/$listname");
	@filelist = <LISTIN>;
	close(LISTIN);

}

sub save_list {
	
	$listname = $_[0];

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

	
}

sub get_list {
	
	#CONTROL ist eine named pipe, open blockt!
	open(CONTROL, "$basedir/control");
	@filelist = <CONTROL>;
	close(CONTROL);

}

sub init {
	# well, it's called "init". guess.
	
	$lastvotes_file = "$savedir/lastvotes";
	
	# open filelist and read it into memory
	if ($ARGV[0]) {
		open (FILELIST, $ARGV[0]);
		@filelist = <FILELIST>;
	} elsif ( -e "$list_dir/default" ) {
		open(FILELIST, "$list_dir/default");
		@filelist = <FILELIST>;
	} else { die("No filelist available in $list_dir"); }
	
	# read last votes
	open (LASTVOTES, $lastvotes_file);
	$lastvotes_pointer = <LASTVOTES>;
	chomp($lastvotes_pointer);
	@lastvotes = <LASTVOTES>;
	close(LASTVOTES);
	
	# initialize random
	srand;
	
	# setup $basedir
	mkdir($basedir);	
	
	# tell STDERR and STDOUT where they can dump their messages
	open (STDERR, ">>$basedir/err");
	open (STDOUT, ">>/dev/null");
	
	# make fifos
	system("/usr/bin/mkfifo /tmp/oyster/control");
	system("/usr/bin/mkfifo /tmp/oyster/kidplay");
	system("/bin/chmod 666 /tmp/oyster/control");
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
		$voteentry = $file; chomp($voteentry);
		$votelist{$voteentry} = 0;
		&process_vote;
	} else {
		if ( int(rand(30)) < 10 ) {
			$index = rand @lastvotes;
			$file = $lastvotes[$index];
		} else {		
			$index = rand @filelist;
			$file = $filelist[$index];
		}

		if ( -e "$savedir/blacklist" ) {
			open(BLACKLIST, "$savedir/blacklist");
			while( $regexp = <BLACKLIST> ) {
				chomp($regexp);
				if ( $file =~ /\Q$regexp/ ) {
					choose_file();
				}
			}
		}	
	}
}


sub info_out {
	
	open(INFO, ">$basedir/info");
	print INFO $file; 
	close(INFO);
	print STDERR "info_out zuende\n";
	
}
