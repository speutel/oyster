package oyster::common;

use strict;
use warnings;
use CGI qw/:standard -no_xhtml/;
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
