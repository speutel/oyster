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
print "<td align='center' width='25%'><a href='browse.pl'>Browse</a></td>";
print "<td align='center' width='25%'><a href='search.pl'>Search</a></td>";
print "<td align='center' width='25%'><a href='blacklist.pl'>Blacklist</a></td>";
print "<td align='center' width='25%'><a href='logview.pl'>Logfile</a></td>";
print "</tr></table>";
print "<hr>";

my $mediadir = $config{'mediadir'};
my $search='';

if (param('search')) {
    $search=param('search');
}

print "<form action='search.pl'><input type='text' name='search' value='$search'>";
print "<input type='submit' value='Search'></form>";

my @results = ();
my $cssclass='file2';

if (!($search eq '')) {
    open (LIST, "lists/default");
    my @list = <LIST>;
    foreach my $line (@list) {
	$line =~ s/\Q$mediadir\E//;
	if ($line =~ /\Q$search\E/i) {
	    chomp($line);
	    push (@results, $line);
	}
    }
    @results = sort @results;
    listdir('',0);

}
    
print end_html;

exit 0;

sub listdir {
    my $basepath = $_[0];
    my $counter = $_[1];

    while (($counter < @results) && (($results[$counter] =~ /^\Q$basepath\E\//) || ($basepath eq ''))) {
	my $newpath = $results[$counter];
	$newpath =~ s/^\Q$basepath\E\///;
	if ($newpath =~ /\//) {
	    $newpath =~ /^([^\/]*)/;
	    $newpath = $1;
	    if (!($basepath eq '')) {
		my $escapeddir = uri_escape("$basepath/$newpath", "^A-Za-z");
		print "<div style='padding-left: 1em;'><strong><a href='browse.pl?dir=$escapeddir'>$newpath</a></strong>";
		$newpath = "$basepath/$newpath";
	    }  else {
		my $escapeddir = uri_escape("$newpath", "^A-Za-z");
		print "<strong><a href='browse.pl?dir=$escapeddir'>$newpath</a></strong>";
	    }
	    $counter = listdir("$newpath",$counter);
	    if (!($basepath eq '')) {
		print "</div>\n";
	    }
	} else {
	    print "<div style='padding-left: 1em;'>";
	    while ($results[$counter] =~ /^\Q$basepath\E\//) {
		my $filename = $results[$counter];
		$filename =~ s/^.*\///;
		$filename =~ /(.*)\.(...)$/;
		my $nameonly = $1;
		my $escapedfile = uri_escape("$basepath/$filename", "^A-Za-z");
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
