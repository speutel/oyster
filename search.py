#!/usr/bin/python
# -*- coding: ISO-8859-1 -*
# oyster - a perl-based jukebox and web-frontend
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

import cgi
import config
import fifocontrol
import cgitb
import sys
import common
import re
cgitb.enable()

myconfig = config.get_config('oyster.conf')
basedir = myconfig['basedir']
mediadir = myconfig['mediadir'][:-1]
form = cgi.FieldStorage()

common.navigation_header()

if form.has_key('searchtype') and form['searchtype'].value == 'regex':
    searchtype = 'regex'
    regexcheck = "checked='checked'"
    normalcheck = ''
else:
    searchtype = 'normal'
    normalcheck = "checked='checked'"
    regexcheck = ''
    
# Check in which playlist to search

if form.has_key('playlist') and form['playlist'].value == 'current':
    playlist = config.get_playlist()
    curcheck = "checked='checked'"
    allcheck = ''
elif form.has_key('playlist') and form['playlist'].value == 'all':
    playlist = 'default'
    allcheck = "checked='checked'"
    curcheck = ''
else:
    curcheck = "checked='checked'"
    allcheck = ''

if form.has_key('search'):
    search = form['search'].value
else:
    search = ''

# Create form

print "<form method='post' action='search.py' enctype='application/x-www-form-urlencoded'>"


print "<table border='0'><tr><td><input type='text' name='search' value='" + search + "'></td>"
print "<td><input type='submit' name='.submit' value='Search' style='margin-left: 2em;'></td></tr>"
print "<tr><td><input type='radio' name='searchtype' value='normal' " + normalcheck + "> Normal<br>"
print "<input type='radio' name='searchtype' value='regex' " + regexcheck + "> Regular Expression<br></td>"
print "<td><input type='radio' name='playlist' value='current' " + curcheck + "> Only current playlist<br>"
print "<input type='radio' name='playlist' value='all' " + allcheck + "> All Songs<br></td></tr></table><div>"
print "</div></form>"

results = []
cssclass = 'file2'

if search != '':

    listfile = open(myconfig['savedir'] + 'lists/' + playlist)
    list = listfile.readlines()
    listfile.close()

    # Compare filenames with searchstring and add
    # them to results

    if searchtype == 'normal':
        for line in list:
            line = line.replace(mediadir,'')
            if line.lower().find(search.lower()) > -1:
                results.append(line[:-1])
    elif searchtype == 'regex':
        for line in list:
            line = line.replace(mediadir,'',1)
            name = line[:-4]
            matcher = re.match(search,name.lower())
            if matcher != None:
                results.append(line[:-1])

    # Sort results alphabetically

    results.sort()
    common.results = results
    results = common.sort_results('/')

    # List directory in browser

    if results != []:
        common.listdir('/',0,cssclass)
    else:
        print "<p>No songs found.</p>"

print "</body></html>"
