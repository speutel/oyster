#!/usr/bin/perl
use CGI qw/:standard -no_xhtml/;
use URI::Escape;
use strict;
use oyster::conf;
use oyster::taginfo;
use oyster::fifocontrol;
use oyster::common;

my %config = oyster::conf->get_config('oyster.conf');
my $playlist = oyster::conf->get_playlist();

if (param('action')) {
    oyster::fifocontrol->do_action(param('action'), param('file'), '');
}

oyster::common->navigation_header();

my %score = ();

open (LASTVOTES, "${config{'savedir'}}scores/$playlist") or die $!;
my $line = <LASTVOTES>;
while ($line = <LASTVOTES>) {
    chomp($line);
    if ($score{$line}) {
	$score{$line}++;
    } else {
	$score{$line} = 1;
    }
}
close (LASTVOTES);

print "<table width='100%'>";
print "<tr><th>Song</th><th width='75'>Score</th></tr>";

my $cssclass='file2';

my $maxscore = (sort {$b <=> $a} values(%score))[0];

while ($maxscore > 0) {

    my $printed = 0;

    my @files = ();

    foreach my $key (keys(%score)) {
	if ($score{$key} == $maxscore) { 
	    push(@files, $key);
	}
    }

    @files = sort(@files);

    foreach my $file (@files) {

	$printed = 1;

	my $escapedfile = $file;
	$escapedfile =~ s/\Q$config{'mediadir'}\E//;
	$escapedfile = uri_escape("/$escapedfile", "^A-Za-z");
	my $display = oyster::taginfo->get_tag_light($file);
	
	# $cssclass changes to give each other file
	# another color
	
	if ($cssclass eq 'file') {
	    $cssclass = 'file2';
	} else {
	    $cssclass = 'file';
	}
	
	print "<tr><td><a class='$cssclass' href='fileinfo.pl?file=$escapedfile'>$display</a></td>";
	print "<td align='center'><a class= '$cssclass' href='score.pl?action=scoredown&file=$escapedfile' title='Score down'><img src='themes/${config{'theme'}}/scoredown${cssclass}.png' border='0' alt='-'></a> <span class='$cssclass'><strong>$score{$file}</strong></span>";
	print " <a class='$cssclass' href='score.pl?action=scoreup&file=$escapedfile' title='Score up'><img src='themes/${config{'theme'}}/scoreup${cssclass}.png' border='0' alt='+'></a></td></tr>";	
    }

    $maxscore--;

    if ($printed) { print "<tr><td colspan=2>&nbsp;</td></tr>"; }

}


foreach my $key (sort {$b <=> $a} values(%score)) {

}

print "</table>";

print end_html;
