# oyster - a perl-based jukebox and web-frontend
#
# Copyright (C) 2004 Benjamin Hanzelmann <ben@nabcos.de>, Stephan Windmüller <windy@white-hawk.de>, Stefan Naujokat <git@ethric.de>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

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
		-head=>[
					CGI::meta({-http_equiv => 'Content-Type',
									-content => 'text/html; charset=iso-8859-1'}),
					Link({-rel=>'shortcut icon', -href=>"themes/${config{theme}}/favicon.png"})
		]);

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

sub noframe_navigation {

	print header, start_html(-title=>'Oyster-GUI',
		-style=>{'src'=>"themes/${config{'theme'}}/layout.css"},
		-head=>CGI::meta({-http_equiv => 'Content-Type',
				-content    => 'text/html; charset=iso-8859-1'}));

	noframe_navigation_noheader();

}

sub noframe_navigation_noheader {

	print "<table width='100%'><tr>";
	print "<td align='center' width='12%'><a href='oyster-gui.pl?frames=no'>Current Status</a></td>";
	print "<td align='center' width='13%'><a href='control.pl?frames=no'>Control</a></td>";
	print "<td align='center' width='12%'><a href='browse.pl?frames=no'>Browse</a></td>";
	print "<td align='center' width='13%'><a href='search.pl?frames=no'>Search</a></td>";
	print "<td align='center' width='12%'><a href='playlists.pl?frames=no'>Playlists</a></td>";
	print "<td align='center' width='13%'><a href='blacklist.pl?frames=no'>Blacklist</a></td>";
	print "<td align='center' width='12%'><a href='score.pl?frames=no'>Scoring</a></td>";
	print "<td align='center' width='13%'><a href='statistics.pl?frames=no'>Statistics</a></td>";
	print "</tr></table>";
	print "<hr>";

}

sub get_cover {
	my $albumdir = my $albumname = $_[1];
	my $imagewidth = $_[2];
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
		"' width='". $imagewidth . "' style='float:right' alt='Cover'>";
	}

}

sub remove_html {
	my $input = $_[1];
	$input =~ s/&/&amp;/g;
	$input =~ s/</&lt;/g;
	$input =~ s/>/&gt;/g;
	return $input;
}
