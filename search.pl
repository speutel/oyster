#!/usr/bin/perl
use CGI qw/:standard -no_xhtml/;
use URI::Escape;
use strict;
use oyster::conf;
use oyster::common;

my %config = oyster::conf->get_config('oyster.conf');

oyster::common->navigation_header();

my $mediadir = $config{'mediadir'};
$mediadir =~ s/\/$//;
my $search='';
my $searchtype = 'normal';

if (param('searchtype')) {
    if ((param('searchtype') eq 'regex')) {
	$searchtype = 'regex';
    }
}

if (param('search')) {
    $search=param('search');
}

# Create form

my %labels = ('normal' => ' Normal', 'regex' => ' Regular Expression');

print start_form;

my $textfield = textfield(-name=>'search',-default=>'');
my $radiobuttons = radio_group(-name=>'searchtype',-values=>['normal','regex'],-default=>'normal',
			-linebreak=>'true',-labels=>\%labels);
my $submit = submit(-value=>'Search',-style=>'margin-left: 2em;');

print table({-border=>'0'},
	    Tr([
		td([$textfield,$radiobuttons,$submit])
		])
	    );

print end_form;

my @results = ();
my $cssclass='file2';

if ($search ne '') {

    # Search for files in default list

    my $playlist = oyster::conf->get_playlist();

    open (LIST, "${config{savedir}}lists/$playlist");
    my @list = <LIST>;

    # Compare filenames with $search and add
    # them to @results

    if ($searchtype eq 'normal') {
	foreach my $line (@list) {
	    $line =~ s/\Q$mediadir\E//;
	    if ($line =~ /\Q$search\E/i) {
		chomp($line);
		push (@results, $line);
	    }
	}
    } elsif ($searchtype eq 'regex') {
	foreach my $line (@list) {
	    $line =~ s/\Q$mediadir\E//;
	    if ($line =~ /$search/i) {
		chomp($line);
		push (@results, $line);
	    }
	}
    }

    # Sort @results alphabetically

    @results = sort @results;

    # Determine maximum depth of directories for
    # further sorting

    my $maxdepth = -1;
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

    # Sort directories before files in every depth

    while ($maxdepth >= 0) {
	@results = sort_results($maxdepth);
	$maxdepth--;
    }

    # List directory in browser

    if (@results > 0) {
	listdir('/',0);
    } else {
	print p('No songs found.');
    }

}
    
print end_html;

exit 0;

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
		print "<table width='100%'><tr>";
		print "<td align='left'><a href='fileinfo.pl?file=$escapedfile' class='$cssclass'>" . escapeHTML($nameonly) . "</a></td>";
		print "<td align='right'><a href='oyster-gui.pl?vote=$escapedfile' class='$cssclass' target='curplay'>Vote</a></td>";
		print "</tr></table>\n";
		$counter++;
	    }
	    print "</div>\n";
	}
    }

    return ($counter);

}

sub sort_results {

    # sort_results sorts a directory by
    # "first dirs, then files in a given depth

    my $depth = $_[0];
    my (@dirs, @files) = ();

    foreach my $result (@results) {
	my $line = $result;
	my $counter = $depth;
	while ($counter > 0) {
	    $line =~ s/^[^\/]*\///;
	    $counter--;
	}

	# If $line contains a '/', it is added to @dirs

	if ($line =~ /\//) {
	    push (@dirs, $result);
	} else {
	    push (@files, $result);
	}
    }

    return (@dirs, @files);

}
