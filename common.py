#!/usr/bin/python
# -*- coding: ISO-8859-1 -*
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


import cgi
import cgitb
import config
import fifocontrol
import os.path
import urllib
import re
import commands
cgitb.enable()

myconfig = config.get_config('oyster.conf')

def navigation_header():

    print "Content-Type: text/html"
    print """
    <?xml version="1.0" encoding="iso-8859-1"?>
    <!DOCTYPE html 
         PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
              "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
     <title>Oyster-GUI</title>
     <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
    """
    print "<link rel='stylesheet' type='text/css' href='themes/" + myconfig['theme'] + "/layout.css' />"
    print "<link rel='shortcut icon' href='themes/" + myconfig['theme'] + "/favicon.png' />"
    print "</head><body>"
    
    print "<table width='100%'><tr>"
    print "<td align='center' width='17%'><a href='browse.py'>Browse</a></td>"
    print "<td align='center' width='16%'><a href='search.py'>Search</a></td>"
    print "<td align='center' width='17%'><a href='playlists.py'>Playlists</a></td>"
    print "<td align='center' width='17%'><a href='blacklist.pl'>Blacklist</a></td>"
    print "<td align='center' width='16%'><a href='score.pl'>Scoring</a></td>"
    print "<td align='center' width='17%'><a href='statistics.pl'>Statistics</a></td>"
    print "</tr></table>"
    print "<hr>"

def get_cover(a,b):
    return('')

# sub get_cover {
# 	my $albumdir = my $albumname = $_[1];
# 	my $imagewidth = $_[2];
# 	$albumname =~ s/\/$//;
# 	$albumname =~ s/^.*\///;
# 	my $albumnameus = $albumname;
# 	$albumnameus =~ s/\ /_/g;
# 	my @coverfiles = split(/,/, $config{'coverfilenames'});
# 	my $filetype = 'jpeg';
# 	my $base64 = "";
# 
# 	foreach my $cover (@coverfiles) {
# 		$cover =~ s/\$\{album\}/$albumname/g;
# 		$cover =~ s/\$\{albumus\}/$albumnameus/g;
# 		if (-e "$albumdir$cover") {
# 			open (COVER, "$albumdir$cover");
# 			while (read(COVER, my $buf, 60*57)) {
# 				$base64 = $base64 . encode_base64($buf);
# 			}
# 			close (COVER);
# 			$filetype = 'gif' if ($cover =~ /\.gif$/);
# 			$filetype = 'png' if ($cover =~ /\.png$/);
# 			last;
# 		}
# 	}
# 
# 	if ($base64 eq "") {
# 		return '';
# 	} else {
# 		return "<img src='data:image/$filetype;base64," . $base64 .
# 		"' width='". $imagewidth . "' style='float:right' alt='Cover'>";
# 	}
# 
# }
