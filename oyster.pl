#!/usr/bin/perl

# oyster - a perl-based jukebox and web-frontend
#
# Copyright (C) 2004 Benjamin Hanzelmann <ben@nabcos.de>, 
#  Stephan Windmüller <windy@white-hawk.de>, 
#  Stefan Naujokat <git@ethric.de>
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

use warnings;
use strict;
use oyster::conf;
use File::Find;
use POSIX qw(strftime);

my $savedir = `pwd`;
chomp($savedir);
my $conffile = "$savedir/oyster.conf";
my %config;

my $logtime_format="%Y%m%d-%H%M%S";
my @history;

my $basedir = "/tmp/oyster";
my $media_dir = "/";
my $list_dir = "$savedir/lists";
my $voteplay_percentage = 10;
my $scores_size = 30;
my $votefile = "$basedir/votes";

my $voted_file = "platzhalter";

my ($scores_pointer, @scores);
my $scores_exist = "false";
my (@filelist, $file, $control, %votehash, @votelist);
my $file_override="false"; 
my $skipped = "false";

my $log_playlist = "default";
my $playlist = "default";
my $scores_file = "$savedir/scores/$playlist";




##################
## main program ##
##################

init();
choose_file();
info_out();
play_file();
build_playlist();

while ( 1 ) {
	main();
}





#########################
## defining procedures ##
#########################

sub main {

	get_control();
	interpret_control();
	choose_file();
	info_out();
	play_file();

}

sub init {
	# well, it's called "init". guess.

	## set values from config
	%config = oyster::conf->get_config($conffile);

	$savedir = "$config{savedir}";
	$savedir =~ s/\/$//;
	$list_dir = "$config{savedir}/lists";
	$scores_file = "$config{savedir}/scores/$playlist";
	$votefile = "$config{basedir}/votes";
	$media_dir = $config{"mediadir"};
	if ( ! ($media_dir =~ /.*\/$/) ) {
		$media_dir = $media_dir . "/";
	}
	$basedir = $config{basedir};

	$voteplay_percentage = $config{"voteplay"};
	$scores_size = $config{'maxscored'};


	# setup $basedir
	if ( ! -e $basedir) {
		mkdir($basedir);
	} else {
		open(OTHER, "$basedir/pid");
		my $otherpid = <OTHER>;
		close(OTHER);
		chomp($otherpid);

		my $othercmd = "platzhalter";

		if ( $otherpid ne "" ) {
			$othercmd = `ps -o command= -p $otherpid`;
		}

		if ( $othercmd =~ /oyster\.pl/ ) {
			open(OTHER, ">$basedir/control");
			print OTHER "UNPAUSE\n";
			close(OTHER);
			exit;
		} else {
			unlink($basedir);
		}

		mkdir($basedir);
	}
	
	# setup $savedir
	if ( ! -e $savedir ) {
		mkdir($savedir);
	}
	if ( ! -e "$savedir/lists" ) {
		mkdir("$savedir/lists");
	}
	if ( ! -e "$savedir/blacklists" ) {
		mkdir("$savedir/blacklists"); 
	}
	if ( ! -e "$savedir/scores" ) {
		mkdir("$savedir/scores" )
	}
	if ( ! -e "$savedir/logs" ) {
		mkdir("$savedir/logs" )
	}


	open(PID, ">$basedir/pid");
	print PID "$$\n";
	close(PID);

	open (PLAYLIST, ">$basedir/playlist");
	print PLAYLIST "default\n";
	close (PLAYLIST);

	$playlist = "default";

	# read old default-playlist (choose_file needs this for the first start)
	open(DEFAULTLIST, "$savedir/lists/default");
	@filelist = <DEFAULTLIST>;
	close(DEFAULTLIST);
	
	$media_dir =~ s/\/$//;

	update_scores();

	# initialize random
	srand;

	# tell STDERR and STDOUT where they can dump their messages
	open (STDERR, ">>$basedir/err");
	open (STDOUT, ">>/dev/null");
	#open (DEBUG, ">/tmp/debug");
	open (LOG, ">>$savedir/logs/$playlist");
	my $randomfile = ">>/tmp/oyster-random." . `date +%Y%m%d-%H%M`;
	open (RANDOM, $randomfile);

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

		#print STDERR "playnext: $file";

		add_log($file, "VOTED");
		# playnext is set by process_vote
		# set votes for the played file to 0 and reprocess votes
		# (write next winner to playnext, 
		# no winner -> no playnext -> normal play)
		my $voteentry = $file; chomp($voteentry);
		$votehash{$voteentry} = 0;
		&process_vote;
	} else {
		my $random = int(rand(100));
		#print RANDOM "Zufallszahl fuer voteplay ist: $random (<$voteplay_percentage fuer scores)\n";
		if ( $random < $voteplay_percentage ) {
			if ( $scores_exist eq "true" ) {
				# choose file from scores with a chance of $voteplay_percentage/100
				my $index = int(rand($#scores));
				print RANDOM "$playlist scores: $index (index ist $#scores)\n";
				#my $index = rand @scores;
				$file = $scores[$index];
				add_log($file, "SCORED");
			} else {
				$file = " ";
			}
		} else {
			# choose file from "normal" filelist
			my $index = int(rand($#filelist));
			print RANDOM "$playlist filelist: $index (index ist $#filelist)\n";
			#my $index = rand @filelist;
			$file = $filelist[$index];
			add_log($file, "PLAYLIST");
		}

		# read regexps from $savedir/blacklist (one line per regexp)
		# and if $file matches, choose again
		if ( -e "$savedir/blacklists/$playlist" ) {
			my $tmpfile = $file;
			$tmpfile =~ s/\Q$media_dir//;
			print "$savedir/blacklists/$playlist\n";
			open(BLACKLIST, "$savedir/blacklists/$playlist");
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


sub get_control {
	# get control-string from control-FIFO

	open(CONTROL, "$basedir/control") || die "get_control: could not open control\n";
	$control = <CONTROL>;
	close(CONTROL);

}


sub play_file {
	# start play.pl and tell it which file to play
	
	my $escaped_file = $file;
	$escaped_file =~ s/\`/\\\`/g;
	
	system("./play.pl &");

	open(KIDPLAY, ">/tmp/oyster/kidplay");
	print STDERR "play.pl: $file";
	print STDERR "escaped:$escaped_file";
	print KIDPLAY "$escaped_file\n";
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
	
	if ( $playlist ne $log_playlist ) {
		$log_playlist = $playlist;
		close(LOG);
		open(LOG, ">>$savedir/logs/$playlist");
	}
	
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

	elsif ( $control =~ /^ENQUEUE/ ) {

		## enqueue a file (vote without add-scores
		
		$control =~ /^ENQUEUE\ (.*)$/;
		my $file=$1;
		# test for media
		if ( ! ($file =~ /^$media_dir/) ) {
			## TODO use perl replacement for realpath
			$file = $media_dir . "/" . $file;
			$file =~ s/\/\//\//g;
			#$file =~ s/\ /\\\ /g;
			#$file =~ s/\(/\\\(/g;
			#$file =~ s/\)/\\\)/g;
			#$file =~ s/\`/\\\`/g;
			#$file =~ s/\"/\\\"/g;
			#$file =~ s/\'/\\\'/g;
			#open ( RP, "realpath $file |" );
			#$file = <RP>;
			#close(RP);
			#chomp($file);
		}
		print STDERR $file;
		enqueue($file);
		process_vote();
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
		$control =~ /^UNVOTE\ (.*)/;
		my $unvote_file = $1;
		chomp($unvote_file);
		for (my $i = 1; $i <= $votehash{$unvote_file}; $i++) {
			remove_score($unvote_file);
		}
		unvote($1);
		process_vote("noremove");
		get_control();
		interpret_control();
	}	

	elsif ( $control =~ /^SCORE/ ) {

		## adds or removes a file to scores-list
		$control =~ /^SCORE\ (.)\ (.*)/;
		my $scored_file = $2;
		if ( $1 eq "+" ) {
			add_score($scored_file);
		} elsif ($1 eq "-" ) {
			remove_score($scored_file);
		}


		get_control();
		interpret_control();
	}

	elsif ( $control =~ /^ENQLIST/ ) {

		## takes an m3u-list and enqueues the playlist
		$control =~ /^ENQLIST\ (.*)/;
		enqueue_list($1);
		get_control();
		interpret_control();
	}

	else { # fall through
		get_control();
		interpret_control();
	}
}

sub remove_score {
	# $myfile mit newline am Ende!
	my $myfile = $_[0];

	for ( my $i = 0; $i <= $#scores; $i++ ) {
		if ( $scores[$i] eq ($myfile . "\n") ) {
			splice(@scores, $i, 1);
			if ( $scores_pointer > $#scores ) {
				--$scores_pointer;
			}
			last;
		}
	}
	open(SCORED, ">$scores_file");
	print SCORED $scores_pointer . "\n";
	foreach my $entry ( @scores ) {
		print SCORED $entry;
	}
	close(SCORED);
}

sub enqueue_list {
	my $list = $_[0];

	my $list_path = $list;
	$list_path =~ s@/[^/]*$@/@;
	#$list_path =~ s/\ /\\\ /g;

	open(LIST, $list) || print STDERR "enqueue_list: could not open playlist\n";
	while( my $line = <LIST> ) {
		if ( $line =~ /^\#/ ) {
			next;
		} elsif ( $line =~ /^[^\/]/ ) {
			chomp($line);
			$line = $list_path . $line;
			#$line =~ s/([^\\])\ /$1\\\ /g;
			#open( REALPATH, "realpath $line |" );
			#my $enqueue_file = <REALPATH>;
			#chomp($enqueue_file);
			enqueue($line);
			#close( REALPATH );
		} elsif ( $line =~ /^$media_dir/ ) {
			chomp($line);
			enqueue($line);
		} else {
			print STDERR "file not inside media_dir: $line";
		}
	}
	close(LIST);
	process_vote();
}


sub get_player_pid {
	#TODO add support for players set in the config file
	my $player_pid;

	open(PLAYERPID, "$basedir/player_pid");
	$player_pid = <PLAYERPID>;
	close(PLAYERPID);
	chomp($player_pid);
	return $player_pid;
}

sub unvote {
	my $unvote_file = $_[0];

	for ( my $i = 0; $i <= $#votelist; $i++ ) {
		if ($unvote_file eq $votelist[$i]) {
			$votehash{$votelist[$i]} = 0;
			splice(@votelist, $i, 1);
			last;
		}
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

sub add_score {
	# scores is a RRD-style filelist, on file per line, oldest file is
	# overwritten when the limit is reached
	my $added_file = $_[0];

	$scores_pointer = ++$scores_pointer % $scores_size;
	$scores[$scores_pointer] = $added_file . "\n";
	$scores_exist = "true";

	open(SCORED, ">$scores_file") || print STDERR "add_score: could not open scores_file\n";
	print SCORED $scores_pointer . "\n";
	foreach my $entry ( @scores ) {
		print SCORED $entry;
	}
	close(SCORED);
}

sub process_vote {

	$voted_file = $_[0];

	print STDERR "voted for $voted_file\n";

	my $winner = "";
	my $max_votes = 0;

	unlink("$basedir/playnext");

	if ( $voted_file ne "") {
		# if a file is given add it to votelist and scores
		if ( $voted_file ne "noremove" ) {
			# if only the winner is should be recomputed the given song is "noremove"
			enqueue($voted_file);
			add_score($voted_file);
		}
	} else {
		# else remove the file that is playing at the moment from the votelist.
		my $tmpfile = $file;
		chomp $tmpfile;
		#print STDERR "process_vote: unvoting $tmpfile\n";
		unvote($tmpfile);

	}

	# write $basedir/votes
	open(VOTEFILE, ">$votefile") || print STDERR "process_vote: could not open votefile\n";
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
		#print STDERR "winner is $votelist[$winner]\n";

		open(PLAYNEXT, ">$basedir/playnext") || print STDERR "process_vote: could not open playnext\n";
		print PLAYNEXT $votelist[$winner] . "\n";
		close(PLAYNEXT);

	}

}

sub cleanup {

	## save permanent data
	# save scores-list
	open(SCORED, ">$scores_file") || die "cleanup: could not open scores_file for writing\n";
	print SCORED $scores_pointer . "\n";
	foreach my $entry ( @scores ) {
		print SCORED $entry;
	}
	close(SCORED);

	# cleaning up our files
	unlink <$basedir/*>;
	rmdir "$basedir";

	close(LOG);
}

sub load_list {

	my $listname = $_[0];

	if ( open(LISTIN, "$list_dir/$listname") ) {
		@filelist = <LISTIN>;
		close(LISTIN);
		open(PLAYLIST, ">$basedir/playlist");
		print PLAYLIST $listname . "\n";
		close(PLAYLIST);
		$playlist = $listname;
	} else {
		print STDERR "load_list: could not open list\n";
	}

	update_scores();

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

	open(LISTOUT, ">$list_dir/$listname") || print STDERR "save_list: could not open list for writing\n";
	print LISTOUT @filelist;
	close(LISTOUT);

	open(PLAYLIST, ">$basedir/playlist");
	print PLAYLIST $listname . "\n";
	close(PLAYLIST);

	$playlist = $listname;
	update_scores();
}

sub get_list {

	open(CONTROL, "$basedir/control") || die "could not open control!";
	@filelist = <CONTROL>;
	close(CONTROL);

}

sub update_scores {

	$scores_file = "$savedir/scores/$playlist";

	@scores = "";

	if ( -e $scores_file ) {
		open (SCORED, $scores_file) || die $!;
		$scores_pointer = <SCORED>;
		chomp($scores_pointer);
		@scores = <SCORED>;
		close(SCORED);

		# cut off "dangling" entries
		if ( $#scores > $scores_size ) {
			splice(@scores, $scores_size);
		}

		$scores_exist = "true";
	} else {
		@scores = "";
		$scores_pointer = 0;
		$scores_exist = "false";
	}

}

sub build_playlist {
	#build default filelist - list all files in $media_dir
	#system("find $media_dir -type f -and \\\( -iname '*ogg' -or -iname '*mp3' \\\) -print >$list_dir/default");
	print STDERR "old maxindex filelist: " . $#filelist . "\n";
	@filelist = "";
	find( { wanted => \&is_audio_file, no_chdir => 1 }, $media_dir);

	sub is_audio_file {
		if ( ($_ =~ /ogg$/i) or ($_ =~ /mp3$/i) ) {
			push(@filelist, $_ . "\n");
		}
	}
	
	print STDERR "new maxindex filelist: " . $#filelist . "\n";
	
	open (FILELIST, ">$list_dir/default") || die "init: could not open default filelist";
	print FILELIST @filelist;
	close(FILELIST);
}




sub info_out {

	open(INFO, ">$basedir/info");
	print INFO $file; 
	close(INFO);

}
