#!/usr/bin/perl

# commandline parameters:
# only parameter is a file with a list of musicfiles to choose from randomly. (optional)

#use warnings;
#use strict;

my $conffile = "oyster.conf";
my %config;

my $basedir = "/tmp/oyster";
my $savedir = ".";
my $media_dir = "/";
my $lastvotes_file = "$savedir/lastvotes";

my ($lastvotes_pointer, @lastvotes);
my (@filelist, $file, $control, %votelist);
my ($file_override); 


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
		
		case /^NEXT/	{ 
			system("killall play.pl mpg321 ogg123"); 
		}
		case /^done/ { 
		}
		case /^FILE\ / {
			# set $file and play it *now*
			$control =~ s/\\//g;
			$control =~ /^FILE\ (.*)$/;
			$file = $1;
			$file_override = "true";
			system("killall play.pl mpg321 ogg123");
		}	
		case /^QUIT/	{ 
			system("killall play.pl mpg321 ogg123"); 
			cleanup();
			exit; 
		}
		case /^SAVE\ / {
			# save @filelist with name $1
			$control =~ /^SAVE\ (.*)$/;
			save_list($1);
			get_control();
			interpret_control();
		}
		case /^LOAD\ / {
			# load @filelist with name $1
			$control =~ /^LOAD\ (.*)$/;
			load_list($1);
			get_control();
			interpret_control();
		}
		case /^NEWLIST/ {
			# read list from CONTROL
			get_list();
			get_control();
			interpret_control();
		}
		case /^PRINT/ {
			# print list to CONTROL
			$control =~ /^PRINT\ (.*)$/;
			open(CONTROL, ">$basedir/control");

			# if $1 is present print list $1
			# else print list in memory
			if ( ! $1 ) {
				print CONTROL @filelist;
			} else {
				open(LIST, "$list_dir/$1") || print CONTROL "No such list!\n" && next;
				my @files = <LIST>;
				print CONTROL @files;
			}
			close(CONTROL);
			get_control();
			interpret_control();
		}
		case /^LISTS/ {
			# lists filelists into the FIFO
			open(CONTROL, ">$basedir/control");
			my @lists = <$list_dir/*>;
			foreach my $list ( @lists ) {
				print CONTROL $list . "\n";
			}
			close(CONTROL);
		}
		case /^VOTE\ / {
			# vote for file $1
			$control =~ s/\\//g;
			$control =~ /^VOTE\ (.*)$/;
			process_vote($1);
			get_control();
			interpret_control();
		}
		else {
			# fall through
			get_control();
			interpret_control();
		}
	}
}

sub process_vote {
	
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
	
	foreach my $key (keys %votelist) { 
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
	foreach my $entry ( @lastvotes ) {
		print LASTVOTES $entry;
	}
	close(LASTVOTES);
	
	# cleaning up our files
	unlink <$basedir/*>;
	rmdir "$basedir";

}

sub load_list {
	
	my $listname = $_[0];

	open(LISTIN, "$list_dir/$listname");
	@filelist = <LISTIN>;
	close(LISTIN);

}

sub save_list {
	
	my $listname = $_[0];

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

sub read_config {
	
	open(CONFIG, $conffile) || die "no config found (wanted $conffile)";
	while (  $confline = <CONFIG> ) {
		chop($confline);
		if ( $confline =~ /^[^#]/ ) {
			my ($key, $value) = split("=", $confline);
			$config{$key} = $value;
		}
	}
	
	$basedir = $config{"basedir"};
	$savedir = $config{"savedir"};
	$media_dir = $config{"mediadir"};

}

sub init {
	# well, it's called "init". guess.

	# set dirs
	read_config();
	
	my $list_dir = "$savedir/lists";
	my $lastvotes_file = "$savedir/lastvotes";
	
	# setup $basedir
	if ( ! -x $basedir) {
		mkdir($basedir);
	} else {
		unlink($basedir);
		mkdir($basedir);
	}

	# open filelist and read it into memory
	if ($ARGV[0]) {
		open (FILELIST, $ARGV[0]);
		@filelist = <FILELIST>;
		close(FILELIST);
	} else {
		#build default filelist - list all files in $media_dir
		system("find $media_dir -type f -and -iname '*ogg' -or -iname '*mp3' -print >$list_dir/default");
		open (FILELIST, "$list_dir/default");
    @filelist = <FILELIST>;
		close(FILELIST);
	}

	# read last votes
	open (LASTVOTES, $lastvotes_file);
	$lastvotes_pointer = <LASTVOTES>;
	chomp($lastvotes_pointer);
	@lastvotes = <LASTVOTES>;
	close(LASTVOTES);

	# initialize random
	srand;

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
		# don't touch $file when $file_override ist set
		$file_override = "false";
	} elsif ( -e "$basedir/playnext" ) {
		# set $file to the content of $basedir/playnext		
		open( FILEIN, "$basedir/playnext" );
		$file = <FILEIN>;
		close( FILEIN );
		unlink "$basedir/playnext";

		# playnext is set by processvotes
		# set votes for the played file to 0 and reprocess votes
		# (write next winner to playnext, 
		# no winner -> no playnext -> normal play)
		my $voteentry = $file; chomp($voteentry);
		$votelist{$voteentry} = 0;
		&process_vote;
	} else {
		if ( int(rand(100)) < 10 ) {
			# choose file from lastvotes with a chance of 10/30 = 30%
			my $index = rand @lastvotes;
			$file = $lastvotes[$index];
		} else {
			# choose file from "normal" filelist
			my $index = rand @filelist;
			$file = $filelist[$index];
		}

		# read regexps from $savedir/blacklist (one line per regexp)
		# and if $file matches, choose again
		if ( -e "$savedir/blacklist" ) {
			open(BLACKLIST, "$savedir/blacklist");
			while( my $regexp = <BLACKLIST> ) {
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
