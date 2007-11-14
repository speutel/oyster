#!/usr/bin/python
# -*- coding: ISO-8859-1 -*-

# oyster - a python-based jukebox and web-frontend
#
# Copyright (C) 2004 Benjamin Hanzelmann <ben@nabcos.de>,
#  Stephan Windmüller <windy@white-hawk.de>,
#  Stefan Naujokat <git@ethric.de>
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

import taginfo
import urllib
import re
import cgitb
import sys
cgitb.enable()

import cgi
form = cgi.FieldStorage()

import common
common.navigation_header()

if form.has_key('artist') and form.has_key('song'):
    artist = form['artist'].value
    song = form['song'].value
else:
    print "<h1>Error: Artist or songtitle not specified!</h1></body></html>"
    sys.exit()

try:
    from SOAPpy import WSDL
except ImportError:
    print "<h1>Error: SOAPpy not found. Please install python-soappy to use this function.</h1>"
    print "</body></html>"
    sys.exit()

print "<h1>Lyric for <i>" + artist + " - " + song + "</i></h1>\n"

lyric = WSDL.Proxy("http://lyricwiki.org/server.php?wsdl").getSong(artist.decode("utf-8"), song.decode("utf-8"))["lyrics"]

# Try once again if failed
if lyric == "Not found":
    import time
    time.sleep(5)
    lyric = WSDL.Proxy("http://lyricwiki.org/server.php?wsdl").getSong(artist.decode("utf-8"), song.decode("utf-8"))["lyrics"]

if lyric == "Not found":
    print "The lyric was not found. You may " + \
    "<a href='lyric.py?artist=" + urllib.quote(artist) + \
    "&amp;song=" + urllib.quote(song) + "'>try it again</a> " + \
    "or visit <a href='http://www.lyricwiki.org'>LyricWiki</a> yourself."
else:
    lyric = lyric.encode("utf-8")
    print "<pre id='lyric'>"
    print lyric
    print "</pre>"
    print "<strong>This lyric was received from <a href='http://www.lyricwiki.org'>LyricWiki</a></strong>"

print "</body></html>"
