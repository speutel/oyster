#!/usr/bin/python
# -*- coding: UTF-8 -*-

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
cgitb.enable()

import config
myconfig = config.get_config()
basedir = myconfig['basedir']
mediadir = myconfig['mediadir'][:-1]
import cgi
form = cgi.FieldStorage()

playlist = config.get_playlist()

import common
common.navigation_header()

try:
    listname = form['list'].value
except KeyError:
    listname = playlist

import os.path
import sys
import fifocontrol

if not os.path.exists(myconfig['savedir'] + '/lists/' + playlist):
    print "<h1>Error!</h1>"
    print "<p>Playlist <strong>" + listname + "</strong> could not be found.</p>"
    print "</body></html>"
    sys.exit()

if os.path.exists(myconfig['basedir']):
    oysterruns = 1
else:
    oysterruns = 0

print "<p><a href='playlists.py'>Playlists</a> / " + listname + "</p><br clear='all'/>"

escapedlistname = urllib.quote(listname)

print "<p>"
if playlist != listname:
    print "<span class='file'><a class='file' href='playlists.py?action=loadlist&amp;listname=" + escapedlistname + "' >Load this playlist</a></span>"
else:
    print "<i>Already playing this list</i>"
print "</p>"

songsplayed = 0
logmatcher = re.compile('\A[0-9]{4}[0-9]{2}[0-9]{2}\-[0-9]{2}[0-9]{2}[0-9]{2} ([^ ]*) (.*)\Z')
log = open(myconfig['savedir'] + "logs/" + listname)
for line in log.readlines():
    matcher = logmatcher.match(line[:-1])
    if matcher is not None and matcher.group(1) == 'DONE':
        songsplayed += 1
log.close()

songsinlist = 0
with open(myconfig['savedir'] + "lists/" + listname) as listfile:
    for songsinlist, l in enumerate(listfile, 1):
        pass
listfile.close()

print "<table border='0'>"
print "<tr><td class='fileinfo'>Name: </td><td>" + listname + "</td></tr>"
print "<tr><td class='fileinfo'>Size: </td><td>" + str(songsinlist) + " songs</td></tr>"
print "<tr><td class='fileinfo'>Played: </td><td>" + str(songsplayed) + " songs</td></tr>"
print "<tr><td class='fileinfo'>Actions: </td><td>"
print "<a class='file' href='editplaylist.py?playlist=" + escapedlistname + "'>Edit</a></td>"
print "<tr><td class='fileinfo'>&nbsp;</td><td>"
if listname != playlist and listname != "default":
    print "<a class='file' href='playlists.py?action=move&amp;playlist=" + escapedlistname + "'>Move/Rename</a> "
else:
    print "<span style='color:#999'>Move/Rename</span>"
print "</td></tr>"
print "<tr><td class='fileinfo'>&nbsp;</td><td>"
if listname != playlist and listname != "default":
    print "<a class='file' href='playlists.py?action=confirmdelete&amp;listname=" + escapedlistname + "'>Delete</a> "
else:
    print "<span style='color:#999'>Delete</span>"
print "</td></tr>"
print "</table>"

print "</body></html>"
