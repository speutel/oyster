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

$affects =~ s/&/&amp;/g;

print "<form action='blacklist.pl'>";
print "<table><tr>";
print "<td><input type='text' name='affects' value='$affects'></td>";
print "<td><input type='radio' name='action' value='test' checked> Test only<br>";
print "<input type='radio' name='action' value='add'> Add to Blacklist</td>";
print "<td style='padding-left: 2em;'><input type='submit' value='Go'></td></tr></table>\n</form>\n";

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

    # Count affected files for each rule

    while (my $line = <LIST>) {
	chomp($line);
	$line =~ s/^\Q$mediadir\E//;
	foreach my $blacklistline (@blacklistlines) {
	    if ($line =~ /$blacklistline/i) {
		if ($lineaffects{$blacklistline}) {
		    $lineaffects{$blacklistline}++;
		} else {
		    $lineaffects{$blacklistline} = 1;
		}
	    }
	}
    }
    close (LIST);

    my $totalaffected = 0;

    print "<table width='100%'>";
    foreach my $line (@blacklistlines) {
	$totalaffected += $lineaffects{$line};
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

    # lists the directory $basepath and recursive all subdirs

    my $basepath = $_[0];
    my $counter = $_[1];

    while (($counter < @results) && ($results[$counter] =~ /^\Q$basepath\E/)) {
	my $newpath = $results[$counter];
	$newpath =~ s/^\Q$basepath\E//;
	if ($newpath =~ /\//) {
	    $newpath =~ /^([^\/]*\/)/;
	    $newpath = $1;

	    my $cutnewpath = $newpath;
	    $cutnewpath =~ s/\/$//;
	    my $escapedcutnewpath = $cutnewpath;
	    $escapedcutnewpath =~ s/&/&amp;/g;

	    if (!($basepath eq '/')) {
		my $escapeddir = uri_escape("$basepath$cutnewpath", "^A-Za-z");
		print "<div style='padding-left: 1em;'><strong><a href='browse.pl?dir=$escapeddir'>$escapedcutnewpath</a></strong>\n";
		$newpath = "$basepath$newpath";
	    }  else {
		my $escapeddir = uri_escape("$cutnewpath", "^A-Za-z");
		print "<strong><a href='browse.pl?dir=$escapeddir'>$escapedcutnewpath</a></strong>";
		$newpath = "/$newpath";
	    }
	    $counter = listdir($newpath,$counter);
	     if (!($basepath eq '/')) {
		print "</div>\n";
	    }
	} else {
	    print "<div style='padding-left: 1em;'>";
	    while ($results[$counter] =~ /^\Q$basepath\E/) {
		my $filename = $results[$counter];
		$filename =~ s/^.*\///;
		$filename =~ /(.*)\.(...)$/;
		my $nameonly = $1;
		$nameonly =~ s/&/&amp;/g;
		my $escapedfile = uri_escape("$basepath$filename", "^A-Za-z");
		if ($cssclass eq 'file') {
		    $cssclass = 'file2';
		} else {
		    $cssclass = 'file';
		}
		print "<a href='fileinfo.pl?file=$escapedfile' class='$cssclass'>$nameonly</a><br>\n";
		$counter++;
	    }
	    print "</div>";
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
