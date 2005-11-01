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

if form.has_key('playlist') and form.has_key('mode') and form['mode'].value == 'playlist':
    editplaylist = 1
    mode = '&mode=playlist'
    
    print "Content-Type: text/html; charset=" + myconfig['encoding'] + "\n"
    print "<?xml version='1.0' encoding='" + myconfig['encoding'] + "' ?>"
    print """
    <!DOCTYPE html 
         PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
              "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
     <title>Oyster-GUI</title>
    """
    print "<meta http-equiv='Content-Type' content='text/html; charset=" + myconfig['encoding'] + "' />"
    print "<link rel='stylesheet' type='text/css' href='themes/" + myconfig['theme'] + "/layout.css' />"
    print "<link rel='shortcut icon' href='themes/" + myconfig['theme'] + "/favicon.png' />"
    print "</head><body>"

    print "<ul id='navigation'>"
    print "<li class='double'><a href='browse.py?mode=playlist&amp;playlist=" + urllib.quote(form['playlist'].value) + "'>Browse</a></li>"
    print "<li class='double'><a href='search.py?mode=playlist&amp;playlist=" + urllib.quote(form['playlist'].value) + "'>Search</a></li>"
    print "</ul>"
    
    print "<br/><hr/>"

else:
    editplaylist = 0
    common.navigation_header()
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

print "<fieldset class='searchform'>"
print "<legend class='searchform'>Search for music</legend>"
print "<input id='searchfield' type='text' size='40' name='search' value='" + search + "'/>"
print "<input id='searchsubmit' type='submit' name='.submit' value='Search'/>"
print "<table id='searchoptions'>"
print "<tr><td><input type='radio' name='searchtype' value='normal' " + \
    normalcheck + "/> Normal<br/>"
print "<input type='radio' name='searchtype' value='regex' " + regexcheck + \
    "/> Regular expression<br/></td>"
    
if editplaylist:
    print "<input type='hidden' name='playlist' value='" + form['playlist'].value + "'/>"
    print "<input type='hidden' name='mode' value='playlist'/>"
else:
    print "<td><input type='radio' name='playlist' value='current' " + curcheck + \
        "/> Only current playlist<br/>"
    print "<input type='radio' name='playlist' value='all' " + allcheck + "/> " + \
        "All songs<br/></td>"

print "</tr></table>"
print "</fieldset></form>"

results = []
cssclass = 'file2'

if search != '':

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
            if matcher != None:
                results.append(line[:-1])

    # Sort results alphabetically

    results.sort()
    common.results = results
    results = common.sort_results('/')

    # List directory in browser

    if results != []:
        common.results = results
        if editplaylist:
            common.listdir('/', 0, cssclass, 2, urllib.quote(form['playlist'].value))
        else:
            common.listdir('/', 0, cssclass)
    else:
        print "<p>No songs found.</p>"

print "</body></html>"
