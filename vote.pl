#!/usr/bin/perl
use CGI qw/:standard/;

print header, start_html('Oyster-GUI');

if (param()) {
    $votefile=param('vote');
    $votedir=$votefile;
    $votedir=~s/\/[^\/]*$//;
}

print "<meta http-equiv='refresh' content='1; URL=browse.pl?dir=$votedir'>";

print h2("$votefile");

open (CONTROL, ">>/tmp/oyster/control");
print CONTROL "VOTE $votefile";
close CONTROL;

print end_html;
