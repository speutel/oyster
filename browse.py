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
import common
import config
import taginfo
import fifocontrol
import cgitb
import sys
import os.path
import urllib
import re
cgitb.enable()

myconfig = config.get_config('oyster.conf')
basedir = myconfig['basedir']
mediadir = re.sub('/\Z','',myconfig['mediadir'][:-1])
form = cgi.FieldStorage()

common.navigation_header()

givendir = '/'

if form.has_key('dir'):
    # Check given parameter for possible security risks
    givendir = form['dir'].value + '/'
    givendir = re.sub('//','/',givendir)
    givendir = re.sub('\.\./','',givendir)
    if givendir == '..':
        givendir = '/'

# Is oyster currently running?

oysterruns = 0

if os.path.exists(myconfig['basedir']):
    oysterruns = 1

# Give an option to browse all files or only the playlist

playlist = config.get_playlist()

if form.has_key('playlist'):
    print "<p align='right'><a class='file' href='browse.py",
    print "?dir=" + form['dir'].value + "'>Browse all files</a></p>"
elif playlist != 'default':
    print "<p align='right'><a class='file' href='browse.py?playlist=",
    print playlist + "'>Browse in current playlist</a></p>"

if givendir != '/' and os.path.exists(mediadir + givendir):
    print "<p>" + common.get_cover(mediadir + givendir, "100")

    # split path along "/", create link for every part

    print "<strong>Current directory: "

    dirs = givendir[:-1].split('/')
    incdir = ''
    for partdir in dirs:
        escapeddir = urllib.quote(incdir + partdir)
        escapedpartdir = cgi.escape(partdir)
        if form.has_key('playlist'):
            print "<a href='browse.py?dir=" + escapeddir + "&playlist=",
            print form['playlist'].value + "'>"  + escapedpartdir + "</a> / "
        else:
            print "<a href='browse.py?dir=" + escapeddir + "'>" + escapedpartdir + "</a> / "
        incdir = incdir + partdir + '/'

    print "</strong></p><br clear='all'>"

    # Get the parent directory

    parentdir = re.sub('\A' + re.escape(mediadir), '', givendir)
    if re.search('[^/]*/\Z', parentdir) == None:
        parentdir = ''
    else:
       parentdir = re.sub('/[^/]*/\Z', '', parentdir)


    # Create a link to the parent directory

    parentdir = urllib.quote(parentdir)
    if form.has_key('playlist'):
        print "<a href='browse.py?dir=" + parentdir + "&playlist="
        print urllib.quote(form['playlist'].value) + "'>One level up</a><br><br>"
    else:
        print "<a href='browse.py?dir=" + parentdir + "'>One level up</a><br><br>"


elif not os.path.exists(mediadir + givendir): # if $mediadir == "/": just build filelist, no dir-splitting needed  
    print h1('Error!')
    print "The directory $givendir could not be found."
    print "</body></html>"

files = []
dirs = [] # All files and directories which should be displayed

if form.has_key('playlist'):
    # Browse playlist

    playlist = form['playlist'].value
    playlist = re.sub('//','/',playlist)
    playlist = re.sub('../','',playlist)
    if playlist == '..':
        playlist = ''

    dirhash = {} # All directories in a hash to prevent doubles

    # Collect all matching files and directories

    listfile = open(myconfig['savedir'] + 'lists/' + playlist)
    for line in listfile.readlines():
        line = line[:-1]
        if re.match('\A' + re.escape(mediadir + givendir) + '[^/]*\Z'):
            files.append(line)
        matcher = re.match('\A(' + re.escape(mediadir + givendir) + ')[^/]*)/')
        
        if matcher != None:
            dirhash[matcher.group(1)] = 1
    listfile.close()
    
    # Add all directories to @entries

    for key in dirhash.keys().sort():
        dirs.append(key)

else:

    # Browse all files

    globdir = mediadir + givendir

    # Escape whitespaces and apostrophe

    for dir in os.listdir(globdir):
        if dir[0] != '.':
            # If files and directories exist, add them to @files and @dirs
            if os.path.isdir(globdir + dir):
                dirs.append(globdir + dir)
            elif os.path.isfile(globdir + dir):
                files.append(globdir + dir)

dirs.sort()
files.sort()

print "<table width='100%'>"

# First, display all directories

for dir in dirs:
    dir = dir.replace(mediadir,'')
    escapeddir = urllib.quote(dir)
    dir = cgi.escape(re.sub('\A.*/','',dir))
    print "<tr>"
    if form.has_key('playlist'):
        print "<td><a href='browse.py?dir=" + escapeddir + "&playlist="
        print form['playlist'].value + "'>$dir</a></td>"
    else:
        print "<td><a href='browse.py?dir=" + escapeddir + "'>" + dir + "</a></td>"
    print "<td></td>"
    print "</tr>\n"

# Now display all files

cssfileclass = 'file2'
csslistclass = 'playlist2'

for file in files:
    file = file.replace(mediadir + givendir, '')
    print "<tr>"
    if file[-3:] == 'mp3' or file[-3:] == 'ogg':
        # TODO auf andere Dateitypen und case achten
        escapeddir = givendir + file
        escapeddir = urllib.quote(escapeddir.replace(mediadir,''))

        # alternate colors
        if cssfileclass == 'file':
            cssfileclass = 'file2'
        else:
            cssfileclass = 'file'

        escapedfile = cgi.escape(file)

        print "<td><a class='" + cssfileclass + "' href='fileinfo.pl?file=" \
            + escapeddir + "'>" + escapedfile + "</a></td>"

        # only generate "Vote"-link if oyster is running
        if oysterruns:
            print "<td><a class='" + cssfileclass + "' href='oyster-gui.pl?vote=" \
                + escapeddir + "' target='curplay'>Vote</a></td>"
        else:
            print "<td></td>"
    elif file[-3:] == 'm3u$' or file[-3:] == 'pls': # if we have a list...
        escapeddir = givendir + file
        escapeddir = escapeddir.replace(mediadir,'')
        escapeddir = urllib.quote(escapeddir)

        # alternate colors
        if csslistclass == 'playlist':
            csslistclass = 'playlist2'
        else:
            csslistclass = 'playlist'

        escapedfile = cgi.escape(file)
        print "<td><a class='" + csslistclass + "' href='viewlist.pl?list=" \
            + escapeddir + "'>" + escapedfile + "</a></td>"

        #only generate "Vote"-Link if oyster is running
        if oysterruns:
            print "<td><a class='" + csslistclass + "' href='oyster-gui.pl?votelist=",
            print escapeddir + "' target='curplay'>Vote</a></td>"
        else:
            print "<td></td>"

    else: # some other kind of file
        iscover = 0
        coverfiles = myconfig['coverfilenames'].split(',')
        for cover in coverfiles:
            cover = re.sub('\A.*\.','',cover)
            if file.find('cover') > -1:
                iscover = 1
                
        # if we can do nothing - just print it.
        if iscover == 0:
            print "<td>" + file + "</td>"
            print "<td></td>"

    print "</tr>\n"

print "</table>"
print "</body></html>"
