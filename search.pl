#!/usr/bin/perl
use CGI qw/:standard -no_xhtml/;
use URI::Escape;
use strict;
use oyster::conf;

my %config = oyster::conf->get_config('oyster.conf');

print header, start_html(-title=>'Oyster-GUI',
			 -style=>{'src'=>"themes/${config{'theme'}}/layout.css"},
			 -head=>CGI::meta({-http_equiv => 'Content-Type',
                                           -content    => 'text/html; charset=iso-8859-1'}));

print "<table width='100%'><tr>";
print "<td align='center' width='20%'><a href='browse.pl'>Browse</a></td>";
print "<td align='center' width='20%'><a href='search.pl'>Search</a></td>";
print "<td align='center' width='20%'><a href='blacklist.pl'>Blacklist</a></td>";
print "<td align='center' width='20%'><a href='logview.pl'>Logfile</a></td>";
print "<td align='center' width='20%'><a href='score.pl'>Scoring</a></td>";
print "</tr></table>";
print "<hr>";

my $mediadir = $config{'mediadir'};
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

# These variables control, which radio button is selected

my ($normalchecked, $regexchecked) = '';

if ($searchtype eq 'regex') {
    $regexchecked = 'checked';
} else {
    $normalchecked = 'checked';
}

print "<form action='search.pl'>";
print "<table><tr>";
print "<td><input type='text' name='search' value='$search'></td>";

print "<td><input type='radio' name='searchtype' value='normal' $normalchecked> Normal<br>";
print "<input type='radio' name='searchtype' value='regex' $regexchecked> Regular Expression</td>";
print "<td style='padding-left: 2em;'><input type='submit' value='Search'></td>";
print "</table>";
print "</form>";

my @results = ();
my $cssclass='file2';

if (!($search eq '')) {

    # Search for files in default list

    open (LIST, "lists/default");
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

    listdir('',0);

}
    
print end_html;

exit 0;

sub listdir {

    # listdir shows files from @results, sorted by directories
    # $basepath is cut away for recursive use

    my $basepath = $_[0];
    my $counter = $_[1];

    while (($counter < @results) && (($results[$counter] =~ /^\Q$basepath\E\//) || ($basepath eq ''))) {
	my $newpath = $results[$counter];
	$newpath =~ s/^\Q$basepath\E\///;
	if ($newpath =~ /\//) {

	    # $newpath is directory and becomes the top one

	    $newpath =~ /^([^\/]*)/;
	    $newpath = $1;

	    # do not add padding for the top level directory

	    if (!($basepath eq '')) {
		my $escapeddir = uri_escape("/$basepath/$newpath", "^A-Za-z");
		print "<div style='padding-left: 1em;'><strong><a href='browse.pl?dir=$escapeddir'>$newpath</a></strong>";
		$newpath = "$basepath/$newpath";
	    }  else {
		my $escapeddir = uri_escape("/$newpath", "^A-Za-z");
		print "<strong><a href='browse.pl?dir=$escapeddir'>$newpath</a></strong>";
	    }

	    # Call listdir recursive, then quit padding with <div>

	    $counter = listdir("$newpath",$counter);
	    if (!($basepath eq '')) {
		print "</div>\n";
	    }
	} else {

	    # $newpath is a regular file without leading directory

	    print "<div style='padding-left: 1em;'>";
	    while ($results[$counter] =~ /^\Q$basepath\E\//) {

		# Print all filenames in $basedir

		my $filename = $results[$counter];
		$filename =~ s/^.*\///;
		$filename =~ /(.*)\.(...)$/;
		my $nameonly = $1;
		my $escapedfile = uri_escape("/$basepath/$filename", "^A-Za-z");

		# $cssclass changes to give each other file
		# another color

		if ($cssclass eq 'file') {
		    $cssclass = 'file2';
		} else {
		    $cssclass = 'file';
		}
		print "<table width='100%'><tr>";
		print "<td align='left'><a href='fileinfo.pl?file=$escapedfile' class='$cssclass'>$nameonly</a></td>";
		print "<td align='right'><a href='oyster-gui.pl?vote=$escapedfile' class='$cssclass' target='curplay'>Vote</a></td>";
		print "</tr></table>\n";
		$counter++;
	    }
	    print "</div>";
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
