#!/usr/bin/perl

# commandline parameters:
# only parameter is a file with a list of musicfiles to choose from randomly. (optional)

use warnings;
use strict;
use oyster::conf;
use POSIX qw(strftime);

my $savedir = `pwd`;
chomp($savedir);
my $conffile = "$savedir/oyster.conf";
my %config;

my $logtime_format="%Y%m%d-%H%M%S";
my @history;

my $basedir = "/tmp/oyster";
my $media_dir = "/";
my $lastvotes_file = "$savedir/lastvotes";
my $list_dir = "$savedir/lists";
my $voteplay_percentage = 10;
my $lastvotes_size = 30;
my $votefile = "$basedir/votes";

my $voted_file = "platzhalter";

my ($lastvotes_pointer, @lastvotes);
my $lastvotes_exist = "false";
my (@filelist, $file, $control, %votehash, @votelist);
my $file_override="false"; 
my $skipped = "false";




##################
## main program ##
##################


init();

while ( 1 ) {
	main();
}





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

	open(CONTROL, "$basedir/control");
	$control = <CONTROL>;
	close(CONTROL);

}


sub play_file {
	# start play.pl and tell it which file to play
	
	system("./play.pl &");

	open(KIDPLAY, ">/tmp/oyster/kidplay");
	print STDERR "play.pl: $file";
	print KIDPLAY "$file\n";
	close(KIDPLAY);
		
	open(STATUS, ">$basedir/status");
	print STATUS "playing\n";
	close(STATUS);

	push(@history, $file);

	open(HISTORY, ">>$basedir/history");
	print HISTORY $file;
	close(HISTORY);
}

sub add_log {
	# log ( $file, $cause )
	
	my ($logged_file, $comment);
	
	$comment = $_[1];
	$logged_file = $_[0];
	chomp($logged_file);

	print LOG strftime($logtime_format, localtime) . " $comment $logged_file\n";
	
}

sub interpret_control {
	# find out what to do by checking $control

	if ( $control =~ /^NEXT/)  { 

		## skips song
		
		add_log($file, "SKIPPED");
		
		$skipped = "true";
		my $command = "kill " . &get_player_pid;
		system($command); 
		
		# wait for player to empty cache (without sleep: next player raises an
		# error because /dev/dsp is in use)
		sleep(2);
		
		get_control();
		interpret_control();
	}
	
	elsif ( $control =~ /^done/) { 

		## only used by play.pl to signal end of song
		
		#print STDERR "play.pl is done.\n";
		if ( $skipped ne "true" ) {
			add_log($file, "DONE");
		} else { 
			$skipped = "false";
		}
	}
	
	elsif ( $control =~ /^FILE/) {

		## plays file directly (skips song)
		
		# set $file and play it *now*
		$control =~ s/\\//g;
		$control =~ /^FILE\ (.*)$/;
	
		add_log($file, "SKIPPED");
		$skipped = "true";
		
		$file = $1;
		$file_override = "true";

		add_log($file, "VOTED");
		
		my $command = "kill " . &get_player_pid;
		system($command); 
		
		get_control();
		interpret_control();
	}	
	
	elsif ( $control =~ /^PREV/ ) {

		my $command = "kill " . &get_player_pid;
		
		add_log($file, "SKIPPED");
		$skipped = "true";
		
		system($command); 
		$file = $history[$#history-1];
		$file_override = "true";

		add_log($file, "VOTED");
		
		get_control();
		interpret_control();
	}
	
	elsif ( $control =~ /^QUIT/	) {  

		## quits oyster

		# kill player
		my $command = "kill " . &get_player_pid;
		system($command); 
		
		add_log($file, "QUIT");
		
		# wait for "done" from play.pl
		get_control();
		
		cleanup();
		exit;
	}
	
	elsif ( $control =~ /^SAVE/ ) {
		
		## save playlist with name $1
		
		$control =~ /^SAVE\ (.*)$/;
		save_list($1);
		get_control();
		interpret_control();
	}
	
	elsif ( $control =~ /^LOAD/ ) {

		## load playlist with name $1
		
		$control =~ /^LOAD\ (.*)$/;
		load_list($1);
		get_control();
		interpret_control();
	}
	
	elsif ( $control =~ /^NEWLIST/ )  {
		
		## read list from basedir/control

		get_list();
		get_control();
		interpret_control();
	}
	
	elsif ( $control =~ /^PRINT/)  {

		## print playlist to basedir/control
		
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
	
	elsif ( $control =~ /^LISTS/)  {

		# lists filelists into the FIFO
		open(CONTROL, ">$basedir/control");
		my @lists = <$list_dir/*>;
		foreach my $list ( @lists ) {
			print CONTROL $list . "\n";
		}
		close(CONTROL);
	}
	
	elsif ( $control =~ /^VOTE/ ) {

		## vote for a file

		# remove backslashes (Tab-Completion adds these)
		$control =~ s/\\//g;
		
		$control =~ /^VOTE\ (.*)$/;
		process_vote($1);
		get_control();
		interpret_control();
	}
	
	elsif ( $control =~ /^PAUSE/) {

		## pauses play
		
		# send SIGSTOP to player process
		my $command = "kill -19 " . &get_player_pid;
		system($command);
		
		add_log($file, "PAUSED");
		
		#write status
		open(STATUS, ">$basedir/status");
		print STATUS "paused\n";
		close(STATUS);

		get_control();
		interpret_control();
	}
	
	elsif ( $control =~ /^UNPAUSE/) {

		## continues play
		
		#send SIGCONT to player process
		my $command = "kill -18 " . &get_player_pid;
		system($command);
		
		add_log($file, "UNPAUSED");
		
		# write status
		open(STATUS, ">$basedir/status");
		print STATUS "playing\n";
		close(STATUS);
		
		get_control();
		interpret_control();
	}
	
	elsif ( $control =~ /^UNVOTE/) {
	
		## removes a file from the votelist
		$control =~ s/\\//g;
		$control =~ /^UNVOTE\ (.*)$/;
		unvote($1);
		process_vote();
		get_control();
		interpret_control();
	}	
	
	elsif ( $control =~ /^SCORE/ ) {
		
		## adds or removes a file to lastvotes-list
		$control =~ /^SCORE\ (.)\ (.*)/;
		my $scored_file = $2;
		if ( $1 eq "+" ) {
			add_lastvotes($scored_file);
		} elsif ($1 eq "-" ) {
			for ( my $i = 0; $i <= $#lastvotes; $i++ ) {
				if ( $lastvotes[$i] eq ($scored_file . "\n") ) {
					splice(@lastvotes, $i, 1);
					if ( $lastvotes_pointer != 0 ) {
						--$lastvotes_pointer;
					}
					last;
				}
			}
		}
		
		open(LASTVOTES, ">$lastvotes_file");
		print LASTVOTES $lastvotes_pointer . "\n";
		foreach my $entry ( @lastvotes ) {
			print LASTVOTES $entry;
		}
		close(LASTVOTES);
		
		get_control();
		interpret_control();
	}
	
	elsif ( $control = /^M3U/ ) {
		
		## takes an m3u-list and enqueues the playlist
		$control =~ /^M3U\ (.*)/;
		add_m3u($1);
		get_control();
		interpret_control();
	}
	
	else { # fall through
		get_control();
		interpret_control();
	}
}

sub add_m3u {
	# TODO add support for relative paths
	my $m3u = $_[0];
	
	open(M3U, $m3u);
	while( my $line = <M3U> ) {
		chomp($line);
		enqueue($line);
	}
	close(M3U);
	process_vote();
}


sub get_player_pid {
	#TODO add support for players set in the config file
	my $player_pid;
	open(PS, "ps x -o pid=,comm= |") || print STDERR "ps x -o pid=,comm= | failed\n";
	while( my $line = <PS> ) {
		if ( $line =~ /(mpg321|ogg123)/ ) {
			$line =~ /^[\ ]*([0-9][0-9]*)\ /;
			$player_pid = $1;
			last;
		}
	}
	close(PS);
	return $player_pid;
}

sub unvote {
	my $unvote_file = $_[0];
	chomp($unvote_file);

	for ( my $i = 0; $i <= $#votelist; $i++ ) {
		print STDERR "file to unvote: $unvote_file, ";
		print STDERR "file in votelist: $votelist[$i], ";
		if ($unvote_file eq $votelist[$i]) {
			print STDERR "match: yes!\n";
			$votehash{$votelist[$i]};
			splice(@votelist, $i, 1);
			last;
		}
		print STDERR "match: no\n";
	}
	
}

sub enqueue {
	my $enqueued_file = $_[0];
	
	if ( $votehash{$enqueued_file} ne "" ) {
		if ( $votehash{$enqueued_file} > 0 ) {
			$votehash{$enqueued_file} += 1;
		} else {
			push(@votelist, $enqueued_file);
			$votehash{$enqueued_file} = 1;
		}		
	} else {
		push(@votelist, $enqueued_file);
		$votehash{$enqueued_file} = 1;
	}

}

sub add_lastvotes {
	my $added_file = $_[0];

	$lastvotes_pointer = ++$lastvotes_pointer % $lastvotes_size;
	$lastvotes[$lastvotes_pointer] = $added_file . "\n";
	$lastvotes_exist = "true";
	
	open(LASTVOTES, ">$lastvotes_file");
	print LASTVOTES $lastvotes_pointer . "\n";
	foreach my $entry ( @lastvotes ) {
		print LASTVOTES $entry;
	}
	close(LASTVOTES);
}

sub process_vote {
	
	$voted_file = $_[0];
	
	print STDERR "voted for $voted_file\n";
	
	my $winner = "";
	my $max_votes = 0;
	
	unlink("$basedir/playnext");
	
	if ( $voted_file ne "") {
		# if a file is given add it to votelist and lastvotes
		enqueue($voted_file);
		add_lastvotes($voted_file);
		
	} else {
		# else remove the file that is playing at the moment from the votelist.
		my $tmpfile = $file;
		chomp $tmpfile;
		print STDERR "process_vote: unvoting $tmpfile\n";
		unvote($tmpfile);
	
	}
	
	# write $basedir/votes
	open(VOTEFILE, ">$votefile") || die $!;
	foreach my $entry (@votelist) {
		print VOTEFILE "$entry,$votehash{$entry}\n";
	}
	close(VOTEFILE);
	
	# choose winner: go through @votelist and lookup number of votes in
	# %votehash, set winner to the on with the maximum number of votes
	for ( my $i = 0; $i <= $#votelist; $i++ ) {
		my $entry = $votelist[$i]; 
		if ($votehash{$entry} > $max_votes) {
			print "process_vote: trying $entry for winner\n";
			$winner = $i; $max_votes = $votehash{$entry};
		}
	}
	
	# write winner to playnext
	if ($votehash{$votelist[$winner]} > 0) {
		print STDERR "winner is $votelist[$winner]\n";
		
		open(PLAYNEXT, ">$basedir/playnext") || die $!;
		print PLAYNEXT $votelist[$winner] . "\n";
		close(PLAYNEXT);
	}
	
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

	close(LOG);
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
	
	open(CONTROL, "$basedir/control");
	@filelist = <CONTROL>;
	close(CONTROL);

}

sub init {
	# well, it's called "init". guess.

	## set values from config
	%config = oyster::conf->get_config($conffile);
	
	$list_dir = "$config{savedir}/lists";
	$lastvotes_file = "$config{savedir}/lastvotes";
	$votefile = "$config{basedir}/votes";
	$media_dir = $config{"mediadir"};
	if ( ! ($media_dir =~ /.*\/$/) ) {
		$media_dir = $media_dir . "/";
	}
	
	$voteplay_percentage = $config{"voteplay"};
	$lastvotes_size = $config{'maxlastvotes'};
	

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
		system("find $media_dir -type f -and \\\( -iname '*ogg' -or -iname '*mp3' \\\) -print >$list_dir/default");
		open (FILELIST, "$list_dir/default");
    @filelist = <FILELIST>;
		close(FILELIST);
	}
	
	$media_dir =~ s/\/$//;
	
	# read last votes
	if ( -e $lastvotes_file ) {
		open (LASTVOTES, $lastvotes_file) || die $!;
		$lastvotes_pointer = <LASTVOTES>;
		chomp($lastvotes_pointer);
		@lastvotes = <LASTVOTES>;
		close(LASTVOTES);
		$lastvotes_exist = "true";
	}

	# initialize random
	srand;

	# tell STDERR and STDOUT where they can dump their messages
	open (STDERR, ">>$basedir/err");
	open (STDOUT, ">>/dev/null");
	#open (DEBUG, ">/tmp/debug");
	open (LOG, ">>$savedir/log");

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

		print STDERR "playnext: $file";
		
		add_log($file, "VOTED");
		# playnext is set by process_vote
		# set votes for the played file to 0 and reprocess votes
		# (write next winner to playnext, 
		# no winner -> no playnext -> normal play)
		my $voteentry = $file; chomp($voteentry);
		$votehash{$voteentry} = 0;
		&process_vote;
	} else {
		if ( int(rand(100)) < $voteplay_percentage ) {
			if ( $lastvotes_exist eq "true" ) {
				# choose file from lastvotes with a chance of $voteplay_percentage/100
				my $index = rand @lastvotes;
				$file = $lastvotes[$index];
				add_log($file, "LASTVOTES");
			}
		} else {
			# choose file from "normal" filelist
			my $index = rand @filelist;
			$file = $filelist[$index];
			add_log($file, "PLAYLIST");
		}

		# read regexps from $savedir/blacklist (one line per regexp)
		# and if $file matches, choose again
		if ( -e "$savedir/blacklist" ) {
			my $tmpfile = $file;
			$tmpfile =~ s/\Q$media_dir//;
			open(BLACKLIST, "$savedir/blacklist");
			while( my $regexp = <BLACKLIST> ) {
				chomp($regexp);
				if ( $tmpfile =~ /$regexp/ ) {
					add_log($file, "BLACKLIST");
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

}
