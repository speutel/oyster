#!/usr/bin/perl
use CGI qw/:standard -no_xhtml/;
use URI::Escape;
use strict;

print
    header,
    start_html(-title=>'Oyster-GUI',
	       -style=>{'src'=>'layout.css'},
	       -head=>CGI::meta({-http_equiv => 'Content-Type',
				 -content    => 'text/html; charset=iso-8859-1'}));

my ($votefile, $votedir);

if (param()) {
    $votefile=param('vote');
    $votedir=$votefile;
    $votedir=~s/\/[^\/]*$//;
}

my $escapeddir = uri_escape("$votedir", "^A-Za-z");

print "<meta http-equiv='refresh' content='1; URL=browse.pl?dir=$escapeddir'>";

if (!($votefile eq '')) {
    print h2("$votefile");

    open (CONTROL, ">>/tmp/oyster/control");
    print CONTROL "VOTE $votefile";
    close CONTROL;
}

print end_html;
