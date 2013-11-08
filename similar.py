#!/usr/bin/python
# -*- coding: UTF-8 -*-

# oyster - a python-based jukebox and web-frontend
#
# Copyright (C) 2004 Benjamin Hanzelmann <ben@nabcos.de>, 
#  Stephan WindmÃ¼ller <windy@white-hawk.de>, 
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

"Lists similar artists and number of available songs"

def searchartist(query):

    "Return number of songs on the local system"
    
    num = 0
    for searchline in allfiles:
        if searchline.find(query.lower()) > -1:
            num += 1
    return num

import cgi
form = cgi.FieldStorage()
import cgitb
cgitb.enable()

import config
myconfig = config.get_config()

# Read all files into memory

playlistfile = open(myconfig['savedir'] + 'lists/default')
allfiles = []
for line in playlistfile.readlines():
    allfiles.append(line[:-1].lower())
playlistfile.close()

import common
common.navigation_header()

import urllib
if form.has_key('artist'):
    artist = form['artist'].value
else:
    print "</body></html>"
    import sys
    sys.exit(0)
    
urldata = urllib.urlopen('http://ws.audioscrobbler.com/1.0/artist/' + \
    urllib.quote(artist) + '/similar.txt')

artist_rate = {}
minrate = 30 # TODO minrate hardcoded!

print "<h1>Similar artists for " + artist + "</h1>"
print "<table style='width: 100%'>"
print "<tr><th align='left'>Match</th><th align='left'>Name</th><th></th></tr>"

for line in urldata.readlines():
    try:
        rate, hashcode, name = line[:-1].split(',')
    except ValueError:
        rate = minrate - 1

    # Convert to "integer strings"

    if str(rate).find(".") > -1:
        rate = rate[:rate.find(".")]

    if int(rate) > minrate:
        numsongs = searchartist(name)
        print "<tr><td>" + rate + "</td>"
        similarlink = "<a href='similar.py?artist=" + \
            urllib.quote(name) + "' title='Show similar artists for " + \
            name + "'>" + name + "</a>"
        print "<td>" + similarlink + "</td>"
        if numsongs > 0:
        
            searchlink = "<a href='search.py?searchtype=normal&amp;" + \
                "playlist=all&amp;search=" + urllib.quote(name) + \
                "' title='Show songs'>" + str(numsongs) + " songs</a>"
            print "<td align='right'>" + searchlink + "</td>"
            
        else:
            print "<td></td>"
        print "</tr>" 

print "</table>"
print "</body></html>"
