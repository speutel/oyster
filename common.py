#!/usr/bin/python
# -*- coding: ISO-8859-1 -*-

# oyster - a perl-based jukebox and web-frontend
#
# Copyright (C) 2004 Benjamin Hanzelmann <ben@nabcos.de>,
# Stephan Windmüller <windy@white-hawk.de>, Stefan Naujokat <git@ethric.de>
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

"Provides common functions used by Oyster"

__revision__ = 1

import cgi
import cgitb
import config
import os.path
import urllib
import re
import base64
cgitb.enable()

myconfig = config.get_config('oyster.conf')

def navigation_header():

    "Prints the standard header for most pages of Oyster"

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
    print "<link rel='stylesheet' type='text/css' href='themes/" + \
        myconfig['theme'] + "/layout.css' />"
    print "<link rel='shortcut icon' href='themes/" + myconfig['theme'] + \
        "/favicon.png' />"
    print "</head><body>"
    
    print "<table width='100%'><tr>"
    print "<td align='center' width='17%'><a href='browse.py'>Browse</a></td>"
    print "<td align='center' width='16%'><a href='search.py'>Search</a></td>"
    print "<td align='center' width='17%'>" + \
        "<a href='playlists.py'>Playlists</a></td>"
    print "<td align='center' width='17%'>" + \
        "<a href='blacklist.py'>Blacklist</a></td>"
    print "<td align='center' width='16%'><a href='score.py'>Scoring</a></td>"
    print "<td align='center' width='17%'>" + \
        "<a href='statistics.py'>Statistics</a></td>"
    print "</tr></table>"
    print "<hr/>"

def get_cover (albumdir, imagewidth):

    "Returns a cover-image as a base64-string"

    albumname = os.path.basename(albumdir[:-1])
    albumnameus = albumname.replace(' ', '_')
    coverfiles = myconfig['coverfilenames'].split(',')
    filetype = 'jpeg'
    encoded = ""

    for cover in coverfiles:
        cover = cover.replace('${album}', albumname)
        cover = cover.replace('${albumus}', albumnameus)
        if os.path.exists(albumdir + cover):
            coverfile = open (albumdir + cover)
            encoded = base64.encodestring(coverfile.read())
            coverfile.close()
            filetype = cover[-3:]
            break

    if encoded == "":
        return ''
    else:
        return "<img src='data:image/" + filetype + ";base64," + encoded + \
            "' width='" + imagewidth + "' style='float:right' alt='Cover'/>"

def sort_results (topdir):

    """
    sort_results sorts a directory and its subdirectories by
    "first dirs, then files"
    """

    skip = '' # Do not add directories twice
    dirs = files = []

    for line in results:
        if ((skip != '') and not (line.index(skip) == 0)) or (skip == ''):
            dirmatcher = re.match('\A' + re.escape(topdir) + '([^/]*/)/', line)
            filematcher = re.match('\A' + re.escape(topdir) + '[^/]*/', line)
            if dirmatcher != None:
                # line is a directory
                skip = topdir + dirmatcher.group(1)
                dirs.append(sort_results(skip))
            elif filematcher != None:
                # line is a file
                files.append(line)

    return(dirs + files)

def listdir (basepath, counter, cssclass, playlistmode=0, playlist=''):

    """
    listdir shows files from results, sorted by directories
    basepath is cut away for recursive use
    """

    while counter < len(results) and results[counter].find(basepath) == 0:
        newpath = results[counter]
        newpath = newpath.replace(basepath, '', 1)
        if newpath.find('/') > -1:
            # $newpath is directory and becomes the top one

            matcher = re.match('\A([^/]*/)', newpath)
            newpath = matcher.group(1)

            # do not add padding for the top level directory

            cutnewpath = newpath[:-1]

            if not basepath == '/':
                escapeddir = urllib.quote(basepath + cutnewpath)
                print "<div style='padding-left: 1em;'>"
                if playlistmode:
                    print "<table width='100%'><tr><td align='left'>"
                    print "<strong><a href='browse.py?mode=playlist&dir=" + \
                        escapeddir + "&amp;playlist=" + playlist + \
                        "' target='browse'>" + cgi.escape(cutnewpath) + \
                        + "</a></strong>"
                    print "<td align='right'><a href='editplaylist.py?" + \
                        "playlist=" + playlist + "&deldir=" + escapeddir + \
                        "'>Delete</a></td>"
                    print "</tr></table>"
                else:
                    print "<strong><a href='browse.py?dir=" + escapeddir + \
                        "'>" + cgi.escape(cutnewpath) + "</a></strong>"
                newpath = basepath + newpath
            else:
                escapeddir = urllib.quote("/" + cutnewpath)
                if playlistmode:
                    print "<table width='100%'><tr><td align='left'>"
                    print "<strong><a href='browse.py?mode=playlist&dir=" + \
                        escapeddir + "&amp;playlist=" + playlist + \
                        "' target='browse'>" + cgi.escape(cutnewpath) + \
                        "</a></strong>"
                    print "<td align='right'><a href='editplaylist.py?" + \
                        "playlist=" + playlist + "&deldir=" + escapeddir + \
                        "'>Delete</a></td>"
                    print "</tr></table>"
                else:
                    print "<strong><a href='browse.py?dir=" + escapeddir + \
                        "'>" + cgi.escape(cutnewpath) + "</a></strong>"
                newpath = "/" + newpath

            # Call listdir recursive, then quit padding with <div>

            counter = listdir(newpath, counter, cssclass, playlistmode, playlist)
            if not basepath == '/':
                print "</div></div>\n"

        else:

            # $newpath is a regular file without leading directory

            print "<div style='padding-left: 1em;'>"
            while counter < len(results) and \
                results[counter].find(basepath) == 0:

                # Print all filenames in $basedir

                filename = results[counter]
                filename = os.path.basename(filename)
                matcher = re.match('(.*)\.(...)\Z', filename)
                nameonly = matcher.group(1)
                escapedfile = urllib.quote(basepath + filename)

                # $cssclass changes to give each other file
                # another color

                if cssclass == 'file':
                    cssclass = 'file2'
                else:
                    cssclass = 'file'

                print "<table width='100%'><tr>"
                print "<td align='left'><a href='fileinfo.py?file=" + \
                    escapedfile + "' class='" + cssclass + "'>" + \
                    cgi.escape(nameonly) + "</a></td>"
                if playlistmode:
                    print "<td align='right'><a href='editplaylist.py?" + \
                    "playlist=" + playlist + "&delfile=" + escapedfile + \
                        "' class='" + cssclass + "'>Delete</a></td>"
                else:
                    if os.path.exists(myconfig['basedir']):
                        print "<td align='right'><a href='oyster-gui.py" + \
                        "?vote=" + escapedfile + "' class='" + cssclass + \
                        "' target='curplay'>Vote</a></td>"
                    else:
                        print "<td></td>"
                print "</tr></table>\n"
                counter = counter + 1

    return counter
