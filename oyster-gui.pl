#!/usr/bin/perl
use CGI qw/:standard/;

open(INFO, "/tmp/oyster/info");
$info = <INFO>;
$info = $info . "<br>";
close(INFO);

my $title = "";

if ($info =~ /mp3$/) {
    @output = `id3v2 -l $info`;
    foreach my $line (@output) {
	if ($line =~ /^Title/) {
	    ($title) = m/:\ (.*)$/;
	}
    }
}

print header,
    start_html('Oyster-GUI'),
    h1('Oyster-GUI spielt $title'),
    a({href=>'skip.pl'},'Skip'),
    end_html;

