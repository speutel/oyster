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
