#!/usr/bin/perl
use CGI qw/:standard/;
print header,
    start_html('Oyster-GUI'),
    h1('Oyster-GUI'),
    a({href=>'skip.pl'},'Skip'),
    end_html;

