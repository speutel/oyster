#!/usr/bin/perl

use oyster::conf;

if ( $#ARGV != 0 ) {
	die "This script needs only one commandline-parameter: an oyster-random file.";
}

$conffile = "oyster.conf";
%config = oyster::conf->get_config($conffile);

$listdir = "$config{savedir}/lists";

$scores_file = "$config{savedir}/scores/$playlist";

$dir="/tmp/random-analyse/";

open(RANDOM, $ARGV[0]);

while ( $line = <RANDOM> ) {
	$line =~ s/^([^\ ]*)\ (.*)$/$2/;
	system("mkdir -p " . $dir . $1);
	system("echo '" . $2 . "' >>" . $dir . $1 . "/all");
}

close(RANDOM);

foreach $subdir ( <$dir*> ) {

	$lastdir = $subdir;
	$lastdir =~ s/^.*\/([^\/]*)$/$1/;
	
	open(DIRALL, "$subdir/all");
	while ( $line = <DIRALL> ){
		$line =~ s/^(.*):\ (.*)$/$2/;
		system("echo '" . $2 . "' >>" . $subdir . "/" . $1);
	}
	close(DIRALL);
	system("sort -n $subdir/scores -o $subdir/scores.sorted");
	system("sort -n $subdir/filelist -o $subdir/filelist.sorted");

	open(SCORES, "$config{savedir}/scores/$lastdir");
	open(INLIST, "$subdir/scores.sorted");
	open(OUTLIST, ">$subdir/scores.replaced");

	$i = 0;
	$scoreline = <SCORES>; #erste Zeile ist lastvotes_index, kein Lied
	
	$done = "false";
	
	$line = <INLIST>;
	
	while ( $done ne "true" ) {
		$line =~ /^([0-9]*)\ /;
		$count = $1;

		while ( $i != $count ) {
			$scoreline = <SCORES>;
			$i++;
		}
		chomp($scoreline);
		$line = $scoreline . " " . $line;
		print OUTLIST $line;
		if (! ($line = <INLIST>) ) {
			$done = "true";
		}
	}
	close(OUTLIST);
	close(INLIST);
	close(SCORES);
	

	
	
	
	open(LIST, "$config{savedir}/lists/$lastdir");
	open(INLIST, "$subdir/filelist.sorted");
	open(OUTLIST, ">$subdir/filelist.replaced");

	$i = 0;
	
	$done = "false";
	
	while ( $done ne "true" ) {
		$line =~ /^([0-9]*)\ /;
		$count = $1;

		while ( $i != $count ) {
			$listline = <LIST>;
			$i++;
		}
		chomp($listline);
		$line = $listline . " " . $line;
		print OUTLIST $line;
		if (! ($line = <INLIST>) ) {
			$done = "true";
		}
	}
	close(OUTLIST);
	close(INLIST);
	close(SCORES);
}
