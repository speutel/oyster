#!/usr/bin/perl
use CGI qw/:standard -no_xhtml/;
use URI::Escape;
use strict;

if (param()) {
    my $action=param('action');
    if ($action eq 'skip') {
	open (CONTROL, '>/tmp/oyster/control');
	print CONTROL 'NEXT';
	close CONTROL;
	sleep 1;
    }
}

print
    header,
    start_html(-title=>'Oyster-GUI',
	       -style=>{'src'=>'layout.css'},
	       -head=>CGI::meta({-http_equiv => 'Content-Type',
				 -content    => 'text/html; charset=iso-8859-1'}));

print "<meta http-equiv='refresh' content='30; URL=oyster-gui.pl'>";

open(INFO, "/tmp/oyster/info");
my $info = <INFO>;
chomp($info);
$info =~ s/^np:\ //;
close(INFO);

my ($title, $artist) = "";

if ($info =~ /mp3$/) {
    open (MP3, "id3v2 -l \"$info\"|") or die $!;
    my @output = <MP3>;

    foreach my $line (@output) {
	if ($line =~ /^Title/) {
	    $_ = $line;
	    if ($line =~ /^Title\ \ \:.*Artist/) {
		# id3v1
		($title,$artist) = m/^Title\ \ \:\ (.*)Artist\:\ (.*)/;
		$title =~ s/[\ ]*$//;
	    } else {
		# id3v2
		($title) = m/:\ (.*)$/;
	    }
	} elsif ($line =~ /^Lead/) {
	    $_ = $line;
	    ($artist) = m/:\ (.*)$/;
	}
    }	

    close (MP3);

} elsif ($info =~ /ogg$/) {
    open (OGG, "ogginfo \"$info\"|") or die $!;
    my @output = <OGG>;
    
    foreach my $line (@output) {
	$line =~ s/^\w*//;
	$line =~ s/TITLE=/title=/;
	$line =~ s/ARTIST=/artist=/;
	if ($line =~ /title=/) {
	    $_ = $line;
	    ($title) = m/title=(.*)/;
	} elsif ($line =~ /artist=/) {
	    $_ = $line;
	    ($artist) = m/artist=(.*)/;
	}
    }

    close (OGG);
    
}



if ($title eq "") {
    $title = $info;
    $title =~ s@.*/@@;
    $title =~ s/\.mp3//;
    $title =~ s/\.ogg//;
} else {
    $title = "$artist - $title";
}

$info = uri_escape("$info", "^A-Za-z");

print h1('Oyster');
print "<table width='100%'>";
print "<tr><td><strong>Now playing: <a class='file' href='fileinfo.pl?file=$info' target='browse'>$title</a></strong></td>";
print "<td><a href='oyster-gui.pl?action=skip'>Skip</a></td></tr>";
print "</table>";

open (VOTES, '/tmp/oyster/votes');
my @votes = <VOTES>;

if (-s '/tmp/oyster/votes') {
    print "<table width='100%' style='margin-top:3em;'><tr>";
    print "<th width='70%' align='left'>Voted File</th><th align='center'>Num of votes</th>";
    foreach my $vote (@votes) {
	chomp ($vote);
	my ($numvotes, $title);
	$_ = $vote;
	($title, $numvotes) = m@.*\/(.*),(.*)@;
	$title =~ s/\.mp3$//;
	$title =~ s/\.ogg$//;
	my $escapedvote = $vote;
	$escapedvote =~ s/,[1-9]*$//;
	$escapedvote = uri_escape("$escapedvote", "^A-Za-z");
	print "<tr><td><a class='file' href='fileinfo.pl?file=$escapedvote' target='browse'>$title</a></td><td align='center'>$numvotes</td></tr>\n";
    }
    print "</table>";
}

print end_html;

