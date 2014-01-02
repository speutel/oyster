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

__revision__ = 1

import cgi
import common
import config
import cgitb
import os.path
import urllib
import re
import sys

from common import may_vote
cgitb.enable()

_ = common.get_prefered_language()

myconfig = config.get_config()
basedir = myconfig['basedir']
mediadir = re.sub('/\Z', '', myconfig['mediadir'][:-1])
form = cgi.FieldStorage()
playlist = config.get_playlist()

if 'mode' in form and form['mode'].value == 'editplaylist':
    editplaylist = True
    mode = '&amp;mode=playlist'

    common.html_header(title=_("Browse"))

    print "<ul id='navigation'>"
    print "<li class='double'><a href='browse.py?mode=editplaylist&amp;playlist=" + urllib.quote(form['playlist'].value) +\
          "'>Browse</a></li>"
    print "<li class='double'><a href='search.py?mode=playlist&amp;playlist=" + urllib.quote(form['playlist'].value) +\
          "'>Search</a></li>"
    print "</ul>"
    
    print "<br/><hr/>"
else:
    editplaylist = False
    common.navigation_header(title=_("Browse"))
    mode = ''

if 'dir' in form:
    # Check given parameter for possible security risks
    givendir = form['dir'].value + '/'
    givendir = re.sub('//', '/', givendir)
    givendir = re.sub('\.\./', '', givendir)
    if givendir == '..':
        givendir = '/'
else:
    givendir = '/'

if 'playlist' in form and 'dir' in form and 'checkdir' in form:
    direxists = False
    listfile = open(myconfig['savedir'] + 'lists/' + form['playlist'].value)
    for line in listfile:
        if line.find(mediadir + form['dir'].value) == 0:
            direxists = True
            break
    listfile.close()
    
    if not direxists:
        givendir = '/'

# Is oyster currently running?

if os.path.exists(myconfig['basedir']):
    oysterruns = 1
else:
    oysterruns = 0

# Give an option to browse all files or only the playlist

if not editplaylist:
    if 'dir' in form:
        curdir = urllib.quote(givendir)
    else:
        curdir = '/'
    if 'playlist' in form:
        print "<p ><a class='file' href='browse.py" + \
            "?dir=" + curdir + "'>" + _("Browse all songs") + "</a></p>"
    elif playlist != 'default':
        print "<p ><a class='file' href='browse.py?playlist=" + \
            urllib.quote(playlist) + "&dir=" + curdir + "&checkdir=true'>" + \
            _("Browse in current playlist only") + "</a></p>"

if os.path.exists(mediadir + givendir):

    # split path along "/", create link for every part

    print "<p>"

    if 'playlist' in form:
        print "<a href='browse.py?dir=/" + mode + "&amp;playlist=" + \
            urllib.quote(form['playlist'].value) + "'>Mediadir</a>"
    else:
        if givendir == '/':
            print "<strong>Mediadir</strong>"
        else:
            print "<a href='browse.py?dir=/" + mode + "'>Mediadir</a>"

    dirs = givendir[:-1].split('/')
    incdir = ''
    for partdir in dirs[1:len(dirs)-1]:
        escapeddir = urllib.quote(incdir + partdir)
        escapedpartdir = cgi.escape(partdir)
        if 'playlist' in form:
            print "/ <a href='browse.py?dir=/" + escapeddir + mode + \
                  "&amp;playlist=" + urllib.quote(form['playlist'].value) + "'>" + escapedpartdir + \
                  "</a>"
        else:
            print "/ <a href='browse.py?dir=/" + escapeddir + mode + "'>" + \
                escapedpartdir + "</a>"
        incdir = incdir + partdir + '/'

    partdir = dirs[len(dirs)-1]
    escapedpartdir = cgi.escape(partdir)
    if escapedpartdir != '':
        print "/ <strong>" + escapedpartdir + "</strong>"
    print " /"

    print "</p><br clear='all'/>"

    # Get the parent directory

    """
    parentdir = re.sub('\A' + re.escape(mediadir), '', givendir)
    if re.search('[^/]*/\Z', parentdir) == None:
        parentdir = ''
    else:
        parentdir = re.sub('/[^/]*/\Z', '', parentdir)

    if givendir != '/':
        # Create a link to the parent directory

        parentdir = urllib.quote(parentdir)
        if form.has_key('playlist'):
            print "<a href='browse.py?dir=" + parentdir + mode + "&amp;playlist=" + \
                urllib.quote(form['playlist'].value) + "'>Parent directory</a><br/><br/>"
        else:
            print "<a href='browse.py?dir=" + parentdir + mode + \
                "'>Parent directory</a><br/><br/>"
    """

    print "<p>" + common.get_cover(mediadir + givendir, myconfig['coverwidth']) + "</p>"


elif not os.path.exists(mediadir + givendir):
    # if $mediadir == "/": just build filelist, no dir-splitting needed
    print "<h1>Error!</h1>"
    print "The directory " + givendir + " could not be found."
    print "</body></html>"

files = []
dirs = []  # All files and directories which should be displayed

if 'playlist' in form and not 'mode' in form:
    # Browse playlist

    playlist = form['playlist'].value
    playlist = re.sub('//', '/', playlist)
    playlist = re.sub('../', '', playlist)
    if playlist == '..':
        playlist = ''

    dirhash = {}  # All directories in a hash to prevent doubles

    # Collect all matching files and directories

    listfile = open(myconfig['savedir'] + 'lists/' + playlist)
    for line in listfile.readlines():
        line = line[:-1]
        if re.match('\A' + re.escape(mediadir + givendir) + '[^/]*\Z', line):
            files.append(line)
        matcher = \
            re.match('\A(' + re.escape(mediadir + givendir) + '[^/]*)/', line)
        
        if matcher is not None:
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

    if os.access(globdir, os.R_OK):
        for curdir in os.listdir(globdir):
            if curdir[0] != '.':
                # If files and directories exist, add them to @files and @dirs
                if os.path.isdir(globdir + curdir):
                    dirs.append(globdir + curdir)
                elif os.path.isfile(globdir + curdir):
                    files.append(globdir + curdir)
    else:
        print "Sorry, Oyster does not have not the permission to read this directory!"
        print "</body></html>"
        sys.exit()

dirs.sort()
files.sort()

print "<table>"

# First, display all directories

for curdir in dirs:
    curdir = curdir.replace(mediadir, '')
    escapeddir = urllib.quote(curdir + "/")
    curdir = cgi.escape(re.sub('\A.*/', '', curdir))
    print "<tr>"
    print "<td></td>"
    if 'playlist' in form:
        if editplaylist:
            print "<td><a href='browse.py?dir=" + escapeddir + "&playlist=" + \
                urllib.quote(form['playlist'].value) + mode + "'>" + curdir + "</a></td>"
            print "<td ><a href='editplaylist.py?" + \
                "playlist=" + urllib.quote(form['playlist'].value) + "&adddir=" + \
                escapeddir + "' target='playlist'>Add</a></td>"
        else:
            print "<td><a href='browse.py?dir=" + escapeddir + "&playlist=" + \
                urllib.quote(form['playlist'].value) + mode + "'>" + curdir + "</a></td>"
    else:
        print "<td><a href='browse.py?dir=" + escapeddir + mode + \
            "'>" + curdir + "</a></td>"
    print "</tr>\n"

# Now display all files

cssfileclass = 'file2'
csslistclass = 'playlist2'
alt = '2'

filetypes = myconfig['filetypes'].lower().split(',')

playlistContents = common.get_playlist_contents(playlist)
historyList = common.history(playlist)

for curfile in files:
    curfile = curfile.replace(mediadir + givendir, '')
    print "<tr>"
    if curfile[curfile.rfind(".")+1:].lower() in filetypes:
        dir = givendir + curfile
        dir = dir.replace(mediadir, '')
        escapeddir = urllib.quote(dir)


        # alternate colors
        if cssfileclass == 'file':
            cssfileclass = 'file2'
        else:
            cssfileclass = 'file'

        # more generic alternation
        if alt == '':
            alt = '2'
        else:
            alt = ''
            
        escapedfile = cgi.escape(curfile)

        if editplaylist:
            print "<td><a class='" + cssfileclass + "' href=" + \
                  "'editplaylist.py?playlist=" + urllib.quote(form['playlist'].value) + \
                  "&amp;addfile=" + escapeddir + "' target='playlist'>Add</a></td>"
        else:
            # only generate "Vote"-link if oyster is running
            (mayVote, reason) = may_vote(dir, playlist, playlistContents, historyList)
            if oysterruns and mayVote:
                print "<td><a title='Vote this file' class='" + cssfileclass + "' href='home.py?vote=" + escapeddir +\
                      "' ><img src='themes/" + myconfig['theme'] + "/votefile" + alt + ".png'/></a></td>"
            elif oysterruns and not mayVote:
                print "<td><span class='" + cssfileclass + "' style='font-style: italic;' '>"
                print "<img title='Voting not allowed: " + reason + "' src='themes/" + myconfig['theme'] +\
                      "/notmayvote" + alt + ".png'/>"
                print "</span></td>"
            else:
                print "<td></td>"

        print "<td><a class='" + cssfileclass + "' href='fileinfo.py?file=" \
            + escapeddir + "'>" + escapedfile + "</a></td>"

    elif curfile[-3:] == 'm3u' or curfile[-3:] == 'pls':  # if we have a list...
        escapeddir = givendir + curfile
        escapeddir = escapeddir.replace(mediadir, '')
        escapeddir = urllib.quote(escapeddir)

        # alternate colors
        if csslistclass == 'playlist':
            csslistclass = 'playlist2'
        else:
            csslistclass = 'playlist'

        # more generic alternation
        if alt == '':
            alt = '2'
        else:
            alt = ''

        escapedfile = cgi.escape(curfile)

        if editplaylist:
            print "<td><a class='" + cssfileclass + "' href=" + \
                "'editplaylist.py?add=" + escapeddir + "' target=" + \
                "'playlist'>Add</a></td>"
        else:
            #only generate "Vote"-Link if oyster is running
            if oysterruns:
                print "<td><a title='Enqueue whole list' class='" + csslistclass + "' href='home.py?votelist=" +\
                      escapeddir + "' >"
                print "<img src='themes/" + myconfig['theme'] + "/enqueuelist" + alt + ".png'/>"
                print "</a></td>"
            else:
                print "<td></td>"

        print "<td><a class='" + csslistclass + "' href='viewlist.py?list=" \
            + escapeddir + "'>" + escapedfile + "</a></td>"

    else:  # some other kind of file
        iscover = 0
        coverfiles = myconfig['coverfilenames'].split(',')
        for cover in coverfiles:
            cover = re.sub('\A.*\.', '', cover)
            if curfile.find(cover) > -1:
                iscover = 1
                
        # if we can do nothing - just print it.
        if iscover == 0:
            print "<td></td><td><span style='color:#999'>" + curfile + "</span></td>"

    print "</tr>\n"

print "</table>"
print "</body></html>"
