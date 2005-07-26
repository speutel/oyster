#!/usr/bin/python
# -*- coding: ISO-8859-1 -*-

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

__revision__ = 1

import cgi
import common
import config
import cgitb
import os.path
import urllib
import re
cgitb.enable()

myconfig = config.get_config()
basedir = myconfig['basedir']
mediadir = re.sub('/\Z', '', myconfig['mediadir'][:-1])
form = cgi.FieldStorage()
playlist = config.get_playlist()

if form.has_key('mode') and form['mode'].value == 'playlist':
    editplaylist = 1
    mode = '&mode=playlist'
    
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

else:
    editplaylist = 0
    common.navigation_header()
    mode = ''

if form.has_key('dir'):
    # Check given parameter for possible security risks
    givendir = form['dir'].value + '/'
    givendir = re.sub('//', '/', givendir)
    givendir = re.sub('\.\./', '', givendir)
    if givendir == '..':
        givendir = '/'
else:
    givendir = '/'

if form.has_key('playlist') and form.has_key('dir') and \
    form.has_key('checkdir'):
    
    direxists = 0
    listfile = open(myconfig['savedir'] + 'lists/' + form['playlist'].value)
    for line in listfile:
        if line.find(mediadir + form['dir'].value) == 0:
            direxists = 1
            break
    listfile.close()
    
    if direxists == 0:
        givendir = '/'

# Is oyster currently running?

if os.path.exists(myconfig['basedir']):
    oysterruns = 1
else:
    oysterruns = 0

# Give an option to browse all files or only the playlist

if not editplaylist:
    if form.has_key('dir'):
        curdir = urllib.quote(givendir)
    else:
        curdir = '/'
    if form.has_key('playlist'):
        print "<p align='right'><a class='file' href='browse.py" + \
            "?dir=" + curdir + "'>Browse all files</a></p>"
    elif playlist != 'default':
        print "<p align='right'><a class='file' href='browse.py?playlist=" + \
            playlist + "&dir=" + curdir + "&checkdir=true'>" + \
            "Browse in current playlist</a></p>"

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
            print "<a href='browse.py?dir=" + escapeddir + mode + \
            "&playlist=" + form['playlist'].value + "'>"  + escapedpartdir + \
            "</a> / "
        else:
            print "<a href='browse.py?dir=" + escapeddir + mode + "'>" + \
                escapedpartdir + "</a> / "
        incdir = incdir + partdir + '/'

    print "</strong></p><br clear='all'/>"

    # Get the parent directory

    parentdir = re.sub('\A' + re.escape(mediadir), '', givendir)
    if re.search('[^/]*/\Z', parentdir) == None:
        parentdir = ''
    else:
        parentdir = re.sub('/[^/]*/\Z', '', parentdir)


    # Create a link to the parent directory

    parentdir = urllib.quote(parentdir)
    if form.has_key('playlist'):
        print "<a href='browse.py?dir=" + parentdir + mode + "&playlist=" + \
            urllib.quote(form['playlist'].value) + "'>One level up</a><br/><br/>"
    else:
        print "<a href='browse.py?dir=" + parentdir + mode + \
            "'>One level up</a><br/><br/>"

elif not os.path.exists(mediadir + givendir):
    # if $mediadir == "/": just build filelist, no dir-splitting needed
    print "<h1>Error!</h1>"
    print "The directory " + givendir + " could not be found."
    print "</body></html>"

files = []
dirs = [] # All files and directories which should be displayed

if form.has_key('playlist') and not form.has_key('mode'):
    # Browse playlist

    playlist = form['playlist'].value
    playlist = re.sub('//', '/', playlist)
    playlist = re.sub('../', '', playlist)
    if playlist == '..':
        playlist = ''

    dirhash = {} # All directories in a hash to prevent doubles

    # Collect all matching files and directories

    listfile = open(myconfig['savedir'] + 'lists/' + playlist)
    for line in listfile.readlines():
        line = line[:-1]
        if re.match('\A' + re.escape(mediadir + givendir) + '[^/]*\Z', line):
            files.append(line)
        matcher = \
            re.match('\A(' + re.escape(mediadir + givendir) + '[^/]*)/', line)
        
        if matcher != None:
            dirhash[matcher.group(1)] = 1
    listfile.close()
    
    # Add all directories to @entries

    for key in dirhash.keys():
        dirs.append(key)

    dirs.sort()

else:

    # Browse all files

    globdir = mediadir + givendir

    # Escape whitespaces and apostrophe

    for curdir in os.listdir(globdir):
        if curdir[0] != '.':
            # If files and directories exist, add them to @files and @dirs
            if os.path.isdir(globdir + curdir):
                dirs.append(globdir + curdir)
            elif os.path.isfile(globdir + curdir):
                files.append(globdir + curdir)

dirs.sort()
files.sort()

print "<table width='100%'>"

# First, display all directories

for curdir in dirs:
    curdir = curdir.replace(mediadir,'')
    escapeddir = urllib.quote(curdir + "/")
    curdir = cgi.escape(re.sub('\A.*/', '', curdir))
    print "<tr>"
    if form.has_key('playlist'):
        if editplaylist:
            print "<td><a href='browse.py?dir=" + escapeddir + "&playlist=" + \
                form['playlist'].value + mode + "'>" + curdir + "</a></td>"
            print "<td align='right'><a href='editplaylist.py?" + \
                "playlist=" + form['playlist'].value + "&adddir=" + \
                escapeddir + "' target='playlist'>Add</a></td>"
        else:
            print "<td><a href='browse.py?dir=" + escapeddir + "&playlist=" + \
                form['playlist'].value + mode + "'>" + curdir + "</a></td>"
    else:
        print "<td><a href='browse.py?dir=" + escapeddir + mode + \
            "'>" + curdir + "</a></td>"
    print "<td></td>"
    print "</tr>\n"

# Now display all files

cssfileclass = 'file2'
csslistclass = 'playlist2'

for curfile in files:
    curfile = curfile.replace(mediadir + givendir, '')
    print "<tr>"
    if curfile[-3:] == 'mp3' or curfile[-3:] == 'ogg':
        # TODO auf andere Dateitypen und case achten
        escapeddir = givendir + curfile
        escapeddir = urllib.quote(escapeddir.replace(mediadir,''))

        # alternate colors
        if cssfileclass == 'file':
            cssfileclass = 'file2'
        else:
            cssfileclass = 'file'

        escapedfile = cgi.escape(curfile)

        print "<td><a class='" + cssfileclass + "' href='fileinfo.py?file=" \
            + escapeddir + "'>" + escapedfile + "</a></td>"

        if editplaylist:
            print "<td><a class='" + cssfileclass + "' href=" + \
            "'editplaylist.py?playlist=" + form['playlist'].value + \
            "&addfile=" + escapeddir + "' target='playlist'>Add</a></td>"
        else:
            # only generate "Vote"-link if oyster is running
            if oysterruns:
                print "<td><a class='" + cssfileclass + "' " + \
                "href='oyster-gui.py?vote=" + escapeddir + "' " + \
                "target='curplay'>Vote</a></td>"
            else:
                print "<td></td>"
    elif curfile[-3:] == 'm3u' or curfile[-3:] == 'pls': # if we have a list...
        escapeddir = givendir + curfile
        escapeddir = escapeddir.replace(mediadir,'')
        escapeddir = urllib.quote(escapeddir)

        # alternate colors
        if csslistclass == 'playlist':
            csslistclass = 'playlist2'
        else:
            csslistclass = 'playlist'

        escapedfile = cgi.escape(curfile)
        print "<td><a class='" + csslistclass + "' href='viewlist.py?list=" \
            + escapeddir + "'>" + escapedfile + "</a></td>"

        if editplaylist:
            print "<td><a class='" + cssfileclass + "' href=" + \
                "'editplaylist.py?add=" + escapeddir + "' target=" + \
                "'playlist'>Add</a></td>"
        else:
            #only generate "Vote"-Link if oyster is running
            if oysterruns:
                print "<td><a class='" + csslistclass + "' href='" + \
                "oyster-gui.py?votelist=" + escapeddir + "' " + \
                "target='curplay'>Vote</a></td>"
            else:
                print "<td></td>"

    else: # some other kind of file
        iscover = 0
        coverfiles = myconfig['coverfilenames'].split(',')
        for cover in coverfiles:
            cover = re.sub('\A.*\.', '', cover)
            if curfile.find(cover) > -1:
                iscover = 1
                
        # if we can do nothing - just print it.
        if iscover == 0:
            print "<td>" + curfile + "</td>"
            print "<td></td>"

    print "</tr>\n"

print "</table>"
print "</body></html>"
