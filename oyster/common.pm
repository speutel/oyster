package oyster::common;

use strict;
use warnings;
use CGI qw/:standard -no_xhtml/;
use MIME::Base64;
use oyster::conf;

my %config = oyster::conf->get_config('oyster.conf');

my $VERSION = '1.0';
	
sub navigation_header {

    print header, start_html(-title=>'Oyster-GUI',
			     -style=>{'src'=>"themes/${config{'theme'}}/layout.css"},
			     -head=>CGI::meta({-http_equiv => 'Content-Type',
					       -content    => 'text/html; charset=iso-8859-1'}));

    print "<table width='100%'><tr>";
    print "<td align='center' width='17%'><a href='browse.pl'>Browse</a></td>";
    print "<td align='center' width='16%'><a href='search.pl'>Search</a></td>";
    print "<td align='center' width='17%'><a href='playlists.pl'>Playlists</a></td>";
    print "<td align='center' width='17%'><a href='blacklist.pl'>Blacklist</a></td>";
    print "<td align='center' width='16%'><a href='score.pl'>Scoring</a></td>";
    print "<td align='center' width='17%'><a href='statistics.pl'>Statistics</a></td>";
    print "</tr></table>";
    print "<hr>";

}

sub get_cover {
    my $albumdir = my $albumname = $_[1];
    $albumname =~ s/\/$//;
    $albumname =~ s/^.*\///;
    my $albumnameus = $albumname;
    $albumnameus =~ s/\ /_/g;
    my @coverfiles = split(/,/, $config{'coverfilenames'});
    my $filetype = 'jpeg';
    my $base64 = "";
    
    foreach my $cover (@coverfiles) {
	$cover =~ s/\$\{album\}/$albumname/g;
	$cover =~ s/\$\{albumus\}/$albumnameus/g;
	if (-e "$albumdir$cover") {
	    open (COVER, "$albumdir$cover");
	    while (read(COVER, my $buf, 60*57)) {
		$base64 = $base64 . encode_base64($buf);
	    }
	    close (COVER);
	    $filetype = 'gif' if ($cover =~ /\.gif$/);
	    $filetype = 'png' if ($cover =~ /\.png$/);
	    last;
	}
    }
    
    if ($base64 eq "") {
	return '';
    } else {
	return "<img src='data:image/$filetype;base64," . $base64 .
	    "' width='100' style='float:right; margin-left:20px; margin-right: 20px;'>";
    }

}
