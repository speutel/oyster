#!/usr/bin/perl
use CGI qw/:standard -no_xhtml/;
use URI::Escape;
use strict;
use oyster::conf;
use oyster::common;

my %config = oyster::conf->get_config('oyster.conf');

oyster::common->navigation_header();

my $savedir = $config{'savedir'};
my $basedir = $config{'basedir'};
my $cssclass = 'file2';
my @results = ();

my $affects = '';
if (param('affects') && (param('action') eq 'test')) {
    $affects = param('affects');
}

$affects = escapeHTML($affects);

# Create form

my %labels = ('test' => ' Test Only', 'add' => ' Add to Blacklist');

print start_form;

my $textfield = textfield(-name=>'affects',-default=>'');
my $radiobuttons = radio_group(-name=>'action',-values=>['test','add'],-default=>'test',
			-linebreak=>'true',-labels=>\%labels);
my $submit = submit(-value=>'Go',-style=>'margin-left: 2em;');

print table({-border=>'0'},
	    Tr([
		td([$textfield,$radiobuttons,$submit])
		])
	    );

print end_form;

print p("<a href='blacklist.pl'>Show current blacklist</a>");

if (param('action') && param('affects')) {
    if (param('action') eq 'test') {
	print_affects(param('affects'));
    } elsif (param('action') eq 'add') {
	add_to_blacklist(param('affects'));
	print_blacklist();
    } elsif (param('action') eq 'delete') {
	delete_from_blacklist(param('affects'));
	print_blacklist();
    }
} else {
    print_blacklist();
}

print end_html;

exit 0;

sub print_blacklist {

    # Opens current blacklist and prints each line

    my @blacklistlines = ();
    open (FILE, "${savedir}blacklist");
    while (my $line = <FILE>) {
	chomp($line);
	push (@blacklistlines, $line);
    }
    close (FILE);

    open (LIST, "${savedir}lists/default");

    my $mediadir = $config{'mediadir'};
    $mediadir =~ s/\/$//;

    my %lineaffects = ();
    my $totalaffected = 0;

    # Count affected files for each rule

    while (my $line = <LIST>) {
	my $isblacklisted = 0;
	chomp($line);
	$line =~ s/^\Q$mediadir\E//;
	foreach my $blacklistline (@blacklistlines) {
	    if ($line =~ /$blacklistline/i) {
		$isblacklisted = 1;
		if ($lineaffects{$blacklistline}) {
		    $lineaffects{$blacklistline}++;
		} else {
		    $lineaffects{$blacklistline} = 1;
		}
	    }
	}
	$totalaffected++ if ($isblacklisted);
    }
    close (LIST);



    print "<table width='100%'>";
    foreach my $line (@blacklistlines) {
	my $escapedline = uri_escape("$line", "^A-Za-z");
	print "<tr><td width='60%'>$line</td>";
	print "<td width='25%' align='left'><a href='blacklist.pl?action=test&amp;affects=$escapedline'>Affects</a> ($lineaffects{$line})</td>";
	print "<td width='15%' align='center'><a href='blacklist.pl?action=delete&amp;affects=$escapedline'>Delete</a></td></tr>";
    }

    print "</table>\n";

    print p(strong("Total files affected:"), $totalaffected);
}

sub print_affects {

    # Shows all files, which are affected by a blacklist-rule

    my $affects = $_[0];
    open (LIST, "${savedir}lists/default");

    # Add all matching lines to @results

    my $mediadir = $config{'mediadir'};
    $mediadir =~ s/\/$//;

    while (my $line = <LIST>) {
	chomp($line);
	$line =~ s/^\Q$mediadir\E//;
	if ($line =~ /$affects/i) {
	    push (@results, $line);
	}
    }
    close (LIST);

    # Sort @results alphabetically

    @results = sort @results;

    # Determine maximum depth of directories for further sorting

    my $maxdepth = 0;
    foreach my $result (@results) {
	my $line = $result;
	my $counter = 0;
	while ($counter < $maxdepth) {
	    $line =~ s/^[^\/]*\///;
	    $counter++;
	}
	if ($line =~ /\//) {
	    $maxdepth++;
	}
    }
    $maxdepth--;

    # Sort @results by a given depth

    while ($maxdepth >= 0) {
	@results = sort_results($maxdepth);
	$maxdepth--;
    }

    if (@results > 0) {
	listdir('/', 0);
    } else {
	print p('No songs match these rule.');
    }
}

sub add_to_blacklist {

    # Appends a rule to the blacklist

    my $affects = $_[0];
    open (BLACKLIST, ">>${savedir}blacklist");
    print BLACKLIST "$affects\n";
    close (BLACKLIST);
}

sub delete_from_blacklist {

    # removes a rule from the blacklist

    my $affects = $_[0];
    system ("cp ${savedir}blacklist ${basedir}blacklist.tmp");
    open (BLACKLIST, "${basedir}blacklist.tmp");
    open (NEWBLACKLIST, ">${savedir}blacklist");
    while (my $line = <BLACKLIST>) {
	if (!($line =~ /^\Q$affects\E$/)) {
	    print NEWBLACKLIST $line;
	}
    }
    close (BLACKLIST);
    close (NEWBLACKLIST);
    system ("rm -f ${basedir}blacklist.tmp");
}

sub listdir {

    # listdir shows files from @results, sorted by directories
    # $basepath is cut away for recursive use

    my $basepath = $_[0];
    my $counter = $_[1];

    while (($counter < @results) && ($results[$counter] =~ /^\Q$basepath\E/)) {
	my $newpath = $results[$counter];
	$newpath =~ s/^\Q$basepath\E//;
	if ($newpath =~ /\//) {

	    # $newpath is directory and becomes the top one

	    $newpath =~ /^([^\/]*\/)/;
	    $newpath = $1;

	    # do not add padding for the top level directory

	    my $cutnewpath = $newpath;
	    $cutnewpath =~ s/\/$//;
	    $cutnewpath = escapeHTML($cutnewpath);

	    if (!($basepath eq '/')) {
		my $escapeddir = uri_escape("$basepath$cutnewpath", "^A-Za-z");
		print "<div style='padding-left: 1em;'>";
		print strong(a({href=>"browse.pl?dir=$escapeddir"},$cutnewpath));
		$newpath = "$basepath$newpath";
	    }  else {
		my $escapeddir = uri_escape("/$cutnewpath", "^A-Za-z");
		print strong(a({href=>"browse.pl?dir=$escapeddir"},$cutnewpath));
		$newpath = "/$newpath";
	    }

	    # Call listdir recursive, then quit padding with <div>

	    $counter = listdir($newpath,$counter);
	    if (!($basepath eq '/')) {
		print "</div>\n";
	    }
	} else {

	    # $newpath is a regular file without leading directory

	    print "<div style='padding-left: 1em;'>";
	    while ($results[$counter] =~ /^\Q$basepath\E/) {

		# Print all filenames in $basedir

		my $filename = $results[$counter];
		$filename =~ s/^.*\///;
		$filename =~ /(.*)\.(...)$/;
		my $nameonly = $1;
		my $escapedfile = uri_escape("$basepath$filename", "^A-Za-z");

		# $cssclass changes to give each other file
		# another color

		if ($cssclass eq 'file') {
		    $cssclass = 'file2';
		} else {
		    $cssclass = 'file';
		}
		print a({href=>"fileinfo.pl?file=$escapedfile",class=>"$cssclass"},escapeHTML($nameonly)), br;
		$counter++;
	    }
	    print "</div>\n";
	}
    }

    return ($counter);

}


sub sort_results {

    # sorts @results by a given directory depth
    # directories first, then regular files

    my $depth = $_[0];
    my (@dirs, @files) = ();

    foreach my $result (@results) {
	my $line = $result;
	my $counter = $depth;
	while ($counter > 0) {
	    $line =~ s/^[^\/]*\///;
	    $counter--;
	}
	if ($line =~ /\//) {
	    push (@dirs, $result);
	} else {
	    push (@files, $result);
	}
    }

    return (@dirs, @files);

}
