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

"""
Oyster-CGI for searching in all files or the current playlist
"""

__revision__ = 1

import cgi
import config
import cgitb
import common
import re
import urllib
cgitb.enable()

myconfig = config.get_config()
basedir = myconfig['basedir']
mediadir = myconfig['mediadir'][:-1]
form = cgi.FieldStorage()

if 'playlist' in form and 'mode' in form and form['mode'].value == 'playlist':
    editplaylist = 1
    mode = '&mode=playlist'

    common.html_header(title="Suchen")

    print "<div data-role='header'>"
    print "<div data-role='navbar'>"
    print "<ul>"
    print "<li><a href='browse.py?mode=playlist&amp;playlist=" + urllib.quote(form['playlist'].value) + "'>Browse</a></li>"
    print "<li><a href='search.py?mode=playlist&amp;playlist=" + urllib.quote(form['playlist'].value) + "'>Search</a></li>"
    print "</ul>"
    print "</div></div>"

    print "<div data-role='content'>"
else:
    editplaylist = 0
    common.navigation_header(title="Suchen")
    mode = ''

if form.has_key('searchtype') and form['searchtype'].value == 'regex':
    searchtype = 'regex'
    regexcheck = "checked='checked'"
    normalcheck = ''
else:
    searchtype = 'normal'
    normalcheck = "checked='checked'"
    regexcheck = ''
    
# Check in which playlist to search

if not editplaylist and form.has_key('playlist') and form['playlist'].value == 'current':
    playlist = config.get_playlist()
    curcheck = "checked='checked'"
    allcheck = ''
elif not editplaylist and form.has_key('playlist') and form['playlist'].value == 'all':
    playlist = 'default'
    allcheck = "checked='checked'"
    curcheck = ''
else:
    playlist = 'default'
    curcheck = "checked='checked'"
    allcheck = ''

if form.has_key('search'):
    search = form['search'].value
else:
    search = ''

# Create form

print "<form method='post' action='search.py' " + \
    "enctype='application/x-www-form-urlencoded'>"

#print "<fieldset class='searchform'>"
#print "<legend class='searchform'>Musik Suchen</legend>"
print "<input id='searchfield' type='search' size='40' name='search' value=\"" + cgi.escape(search, 1) + "\"/>"
print "<input type='hidden' name='searchtype' value='normal'/> "

if editplaylist:
    print "<input type='hidden' name='playlist' value='" + form['playlist'].value + "'/>"
    print "<input type='hidden' name='mode' value='playlist'/>"
else:
    print "<fieldset data-role='controlgroup' data-type='horizontal'>"
    print "<label for='playlist-all'>Aktuelle Liste</label>"
    print "<input type='radio' name='playlist' id='playlist-all' value='current' " + curcheck + " />"
    print "<label for='playlist-current'>&Uuml;berall</label>"
    print "<input type='radio' name='playlist' id='playlist-current' value='all' " + allcheck + " />"
    print "</fieldset>"

print "<input id='searchsubmit' type='submit' name='.submit' value='Suchen'/>"

print "</form>"

results = []
cssclass = 'file2'

if search != '' and len(search) >= 3:

    listfile = open(myconfig['savedir'] + 'lists/' + playlist)
    listlines = listfile.readlines()
    listfile.close()

    # Compare filenames with searchstring and add
    # them to results

    if searchtype == 'normal':
        for line in listlines:
            line = line.replace(mediadir,'')
            if line.lower().find(search.lower()) > -1:
                results.append(line[:-1])
    elif searchtype == 'regex':
        for line in listlines:
            line = line.replace(mediadir, '', 1)
            name = line[:-5]
            matcher = re.match(search, name)
            if matcher is not None:
                results.append(line[:-1])

    # Sort results alphabetically

    results.sort()
    common.results = results
    results = common.sort_results('/')

    # List directory in browser

    if results:
        common.results = results
        if editplaylist:
            common.listdir('/', 0, cssclass, 2, urllib.quote(form['playlist'].value))
        else:
            common.listdir('/', 0, cssclass)
    else:
        print "<p>Keine Songs gefunden.</p>"

else:
    print "<p>Bitte mindestens 3 Zeichen als Suchbegriff eingeben.</p>";

print "</body></html>"
