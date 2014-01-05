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

_ = common.get_prefered_language()

myconfig = config.get_config()
basedir = myconfig['basedir']
mediadir = myconfig['mediadir'][:-1]
form = cgi.FieldStorage()

if 'playlist' in form and 'mode' in form and form['mode'].value == 'playlist':
    editplaylist = 1
    mode = '&mode=playlist'

    common.html_header(title="Suchen")
    
    print "<ul id='navigation'>"
    print "<li class='double'><a href='browse.py?mode=editplaylist&amp;playlist=" +\
          urllib.quote(form['playlist'].value) + "'>" + _("Browse") + "</a></li>"
    print "<li class='double'><a href='search.py?mode=playlist&amp;playlist=" +\
          urllib.quote(form['playlist'].value) + "'>" + _("Search") + "</a></li>"
    print "</ul>"
    
    print "<br/><hr/>"

else:
    editplaylist = 0
    common.navigation_header(title="Suchen")
    mode = ''

if 'searchtype' in form and form['searchtype'].value == 'regex':
    searchtype = 'regex'
    regexcheck = "checked='checked'"
    normalcheck = ''
else:
    searchtype = 'normal'
    normalcheck = "checked='checked'"
    regexcheck = ''
    
# Check in which playlist to search

if not editplaylist and common.is_oyster_running() and 'playlist' in form and form['playlist'].value == 'current':
    playlist = config.get_playlist()
    curcheck = "checked='checked'"
    allcheck = ''
elif not editplaylist and 'playlist' in form and form['playlist'].value == 'all':
    playlist = 'default'
    allcheck = "checked='checked'"
    curcheck = ''
else:
    playlist = 'default'
    curcheck = "checked='checked'"
    allcheck = ''

# In Party-Mode, always search current playlist
if not common.is_show_admin_controls() and common.is_oyster_running():
    playlist = config.get_playlist()

if 'search' in form:
    search = form['search'].value
else:
    search = ''

# Create form

print "<form method='post' action='search.py' " + \
    "enctype='application/x-www-form-urlencoded'>"

#print "<fieldset class='searchform'>"
#print "<legend class='searchform'>Musik Suchen</legend>"
print "<input id='searchfield' type='text' size='40' name='search' value=\"" + cgi.escape(search, 1) + "\"/>"
print "<input id='searchsubmit' type='submit' name='.submit' value='" + _("Search") + "'/>"
print "<table id='searchoptions'>"
print "<tr><td><input type='hidden' name='searchtype' value='normal'/> "

if editplaylist:
    print "<input type='hidden' name='playlist' value='" + form['playlist'].value + "'/>"
    print "<input type='hidden' name='mode' value='playlist'/>"
elif common.is_show_admin_controls():
    print "<td><input type='radio' name='playlist' value='current' " + curcheck + \
        "/> " + _("Current List") + "<br/>"
    print "<input type='radio' name='playlist' value='all' " + allcheck + "/> " + \
        _("All Lists") + "<br/></td>"

print "</tr></table>"
print "</fieldset>"
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
            line = line.replace(mediadir, '')
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
            common.listdir('/', 0, cssclass, 0, playlist)
    else:
        print "<p>" + _("No songs found.") + "</p>"

else:
    print "<p>" + _("Please enter at least three characters as a search criterion.") + "</p>"

print "</body></html>"
