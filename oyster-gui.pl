#!/usr/bin/perl
use CGI qw/:standard/;

open(INFO, "/tmp/oyster/info");
$info = <INFO>;
chomp($info);
$info =~ s/^np:\ //;
close(INFO);

my ($title, $artist) = "";

print header, start_html('Oyster-GUI');

if ($info =~ /mp3$/) {
    open (MP3, "id3v2 -l \"$info\"|") or die $!;
    my @output = <MP3>;

    foreach my $line (@output) {
	if ($line =~ /^Title/) {
	    $_ = $line;
	    ($title) = m/:\ (.*)$/;
	} elsif ($line =~ /^Lead/) {
	    $_ = $line;
	    ($artist) = m/:\ (.*)$/;
	}
	
    }
}

if ($title eq "") {
    $title = $info;
    $title =~ s@.*/@@;
}

print
    h1("Oyster-GUI spielt $artist - $title"),
    a({href=>'skip.sh'},'Skip'),
    end_html;

