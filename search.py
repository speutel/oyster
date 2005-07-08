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
import taginfo
import fifocontrol
import cgitb
import sys
import os.path
import urllib
import common
import re
cgitb.enable()

global cssclass

def sort_results (topdir):

    # sort_results sorts a directory and its subdirectories by
    # "first dirs, then files"

    skip = '' # Do not add directories twice
    dirs = files = []

    for line in results:
        if ((skip != '') and not (line.index(skip) == 0)) or (skip == ''):
            dirmatcher = re.match('\A' + re.escape(topdir) + '([^/]*/)/',line)
            filematcher = re.match('\A' + re.escape(topdir) + '[^/]*/',line)
            if dirmatcher != None:
                # line is a directory
                skip = topdir + dirmatcher.group(1)
                dirs.append(sort_results(skip))
            elif filematcher != None:
                # line is a file
                files.append(line)

    return(dirs + files)

def listdir (basepath, counter, cssclass):

    # listdir shows files from @results, sorted by directories
    # $basepath is cut away for recursive use

    while counter < len(results) and results[counter].find(basepath) == 0:
        newpath = results[counter]
        newpath = newpath.replace(basepath,'',1)
        if newpath.find('/') > -1:
            # $newpath is directory and becomes the top one

            matcher = re.match('\A([^/]*/)',newpath)
            newpath = matcher.group(1)

            # do not add padding for the top level directory

            cutnewpath = newpath[:-1]

            if not basepath == '/':
                escapeddir = urllib.quote(basepath + cutnewpath)
                print "<div style='padding-left: 1em;'>"
                print "<strong><a href='browse.py?dir=" + escapeddir + "'>" + cgi.escape(cutnewpath) + "</a></strong>"
                newpath = basepath + newpath
            else:
                escapeddir = urllib.quote("/" + cutnewpath)
                print "<strong><a href='browse.py?dir=" + escapeddir + "'>" + cgi.escape(cutnewpath) + "</a></strong>"
                newpath = "/" + newpath

            # Call listdir recursive, then quit padding with <div>

            counter = listdir(newpath,counter,cssclass)
            if not basepath == '/':
                print "</div>\n"

        else:

            # $newpath is a regular file without leading directory

            print "<div style='padding-left: 1em;'>"
            while counter < len(results) and results[counter].find(basepath) == 0:

                # Print all filenames in $basedir

                filename = results[counter]
                filename = os.path.basename(filename)
                matcher = re.match('(.*)\.(...)\Z',filename)
                nameonly = matcher.group(1)
                escapedfile = urllib.quote(basepath + filename)

                # $cssclass changes to give each other file
                # another color

                if cssclass == 'file':
                    cssclass = 'file2'
                else:
                    cssclass = 'file'

                print "<table width='100%'><tr>"
                print "<td align='left'><a href='fileinfo.pl?file=" + escapedfile + \
                    "' class='" + cssclass + "'>" + cgi.escape(nameonly) + "</a></td>"
                if oysterruns:
                    print "<td align='right'><a href='oyster-gui.py?vote=" + escapedfile + \
                        "' class='" + cssclass + "' target='curplay'>Vote</a></td>"
                else:
                    print "<td></td>"
                print "</tr></table>\n"
                counter = counter + 1

            print "</div>\n"

    return counter


myconfig = config.get_config('oyster.conf')
basedir = myconfig['basedir']
mediadir = myconfig['mediadir'][:-1]
form = cgi.FieldStorage()

common.navigation_header()

if form.has_key('searchtype') and form['searchtype'] == 'regex':
    searchtype = 'regex'
else:
    searchtype = 'normal'
    
if os.path.exists(myconfig['basedir']):
    oysterruns = 1
else:
    oysterruns = 0

if form.has_key('search'):
    search = form['search'].value
else:
    search = ''

# Create form

print "<form method='post' action='search.py' enctype='application/x-www-form-urlencoded'>"


print "<table border='0'><tr><td><input type='text' name='search' value='" + search + "'></td>"
print "<td><input type='submit' name='.submit' value='Search' style='margin-left: 2em;'></td></tr>"
print "<tr><td><input type='radio' name='searchtype' value='normal' checked='checked'> Normal<br>"
print "<input type='radio' name='searchtype' value='regex'> Regular Expression<br></td>"
print "<td><input type='radio' name='playlist' value='current' checked='checked'> Only current playlist<br>"
print "<input type='radio' name='playlist' value='all'> All Songs<br></td></tr></table><div>"
print "<input type='hidden' name='.cgifields' value='searchtype'><input type='hidden' name='.cgifields' value='playlist'></div>"
print "</form>"

results = []
cssclass = 'file2'

if search != '':

    # Check in which playlist to search
    playlist = 'default'

    if form.has_key('playlist') and form['playlist'].value == 'current':
        playlist = config.get_playlist()

    listfile = open(myconfig['savedir'] + 'lists/' + playlist)
    list = listfile.readlines()
    listfile.close()

    # Compare filenames with $search and add
    # them to @results
    # TODO Kommentar aktualisieren

    if searchtype == 'normal':
        for line in list:
            line = line.replace(mediadir,'')
            if line.lower().find(search.lower()) > -1:
                #TODO Groß-/Kleinschreibung
                results.append(line[:-1])
    elif searchtype == 'regex':
        for line in list:
            line = line.replace(mediadir,'',1)
            name = line[:-4]
            matcher = re.match(search,name.lower())
            if matcher != None:
                results.append(line[:-1])

    # Sort @results alphabetically

    results.sort()
    results = sort_results('/')

    # List directory in browser

    if results != []:
        listdir('/',0,cssclass)
    else:
        print "<p>No songs found.</p>"

print "</body></html>"


