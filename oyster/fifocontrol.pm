# oyster - a perl-based jukebox and web-frontend
#
# Copyright (C) 2004 Benjamin Hanzelmann <ben@nabcos.de>, Stephan Windmüller <windy@white-hawk.de>, Stefan Naujokat <git@ethric.de>
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

package oyster::fifocontrol;

use strict;
use warnings;
use oyster::conf;

my %tag;
my %config = oyster::conf->get_config('oyster.conf');
my $VERSION = '1.0';

sub do_action {

	my $action=$_[1];
	my $file=$_[2];

	$file =~ s@//$@/@;
	$file =~ s/\.\.\///g;
	$file = '' if ($file eq "..");

	my $status = '';
	if (-e "${config{'basedir'}}status") {
		open(STATUS, "${config{'basedir'}}status");
		$status = <STATUS>;
		chomp($status);
		close(STATUS);
	}

	my $mediadir = $config{'mediadir'};
	$mediadir =~ s/\/$//;

	open (CONTROL, ">${config{'basedir'}}control");

	if ($action eq 'skip') {
		print CONTROL 'NEXT';
		close CONTROL;
		sleep 4;
	} elsif ($action eq 'prev') {
		print CONTROL 'PREV';
		close CONTROL;
		sleep 4;
	} elsif ($action eq 'start') {
		close CONTROL;
		system("perl oyster.pl &");
		my $waitmax = 100;
		while (!(-e "${config{'basedir'}}info") && ($waitmax > 0)) {
			sleep 1;
			$waitmax--;
		}
	} elsif ($action eq 'stop') {
		print CONTROL "QUIT";
		close CONTROL;
	} elsif ($action eq 'pause') {
		if ($status eq 'paused') {
			print CONTROL "UNPAUSE";
			$status = 'playing';
		} elsif ($status eq 'playing') {
			print CONTROL "PAUSE";
			$status = 'paused';
		}
		close CONTROL;
	} elsif (($action eq 'scoreup') && ($file)) {
		print CONTROL "SCORE + $mediadir" . $file;
		close CONTROL;
	} elsif (($action eq 'scoredown') && ($file)) {
		print CONTROL "SCORE - $mediadir" . $file;
		close CONTROL;
	} elsif (($action eq 'unvote') && ($file)) {
		print CONTROL "UNVOTE $mediadir" . $file;
		close CONTROL;
	} elsif (($action eq 'loadlist') && ($file)) {
		print CONTROL "LOAD $file";
		close CONTROL;
	} elsif (($action eq 'enqueue') && ($file)) {
		print CONTROL "ENQUEUE $file";
		close CONTROL;
	} elsif (($action eq 'addnewlist') && ($file)) {
		$file =~ s/.*\///;
		open (NEWLIST, ">$config{savedir}lists/$file");
		close (NEWLIST);
	} elsif (($action eq 'delete') && ($file)) {
		$file =~ s/.*\///;
		unlink("$config{savedir}blacklists/$file");
		unlink("$config{savedir}lists/$file");
		unlink("$config{savedir}logs/$file");
		unlink("$config{savedir}scores/$file");
	} elsif ($action eq 'favmode') {
		print CONTROL "FAVMODE";
		close CONTROL;
	} elsif ($action eq 'nofavmode') {
		print CONTROL "NOFAVMODE";
		close CONTROL;
	}



	return $status;

}

sub do_vote {
	my $votefile=$_[1];
	$votefile =~ s/^\///;
	$votefile = $config{'mediadir'} . $votefile;
	open (CONTROL, ">${config{basedir}}control");
	print CONTROL "VOTE $votefile";
	close CONTROL;
	sleep 1;
}

sub do_votelist {
	my $votelist=$_[1];
	$votelist =~ s/^\///;
	$votelist = $config{'mediadir'} . $votelist;
	open (CONTROL, ">${config{basedir}}control");
	print CONTROL "ENQLIST $votelist\n";    
	close CONTROL;
	sleep 1;
}
