#!/usr/bin/python
# -*- coding: ISO-8859-1 -*-

# oyster - a python-based jukebox and web-frontend
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

myconfig = config.get_config()

def navigation_header(header=True, title="Oyster", refreshPage=None):

    "Prints the standard header for most pages of Oyster"

    if header:
        print "Content-Type: text/html; charset=" + myconfig['encoding'] + "\n"
        print "<?xml version='1.0' encoding='" + myconfig['encoding'] + "' ?>"
        print """
<!DOCTYPE html 
     PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
          "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
"""
        print "<title>" + title + "</title>"
        print "<meta http-equiv='Content-Type' content='text/html;charset=" + myconfig['encoding'] + "' />"
        if refreshPage != None:
            print " <meta http-equiv='refresh' content='15; URL=" + refreshPage + "'/>"
        print "<link rel='stylesheet' type='text/css' href='themes/" + \
            myconfig['theme'] + "/mLayout.css' />"
        print "<link rel='shortcut icon' href='themes/" + myconfig['theme'] + \
            "/favicon.png' />"
        print "</head><body>"
        print "<div><a href='mHome.py'><img src='themes/" + myconfig['theme'] + "/logo.png' alt='Oyster' width='200' style='margin-bottom:10px'/></a></div>"
        print "<div style='position:absolute; top:2px; right:2px'>"
        print "</div>"

    print "<ul id='navigation'>"
    print "<li><a href='mHome.py'>&Uuml;bersicht</a></li>"
    print "<li><a href='mBrowse.py'>St&ouml;bern</a></li>"
    print "<li><a href='mSearch.py'>Suchen</a></li>"
    print "</ul><br/>"
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
            "' width='" + imagewidth + "' alt='Cover'/>"

def sort_results (topdir):

    """
    sort_results sorts a directory and its subdirectories by
    "first dirs, then files"

    But do we really need this method?
    """

    skip = '' # Do not add directories twice
    dirs = []
    files = []

    dirregexp = re.compile('\A' + re.escape(topdir) + '([^/]+)/')
    fileregexp = re.compile('\A' + re.escape(topdir) + '[^/]*')

    for line in results:
        if ((skip != '') and not (line.find(skip) == 0)) or (skip == ''):
            dirmatcher = dirregexp.match(line)
            filematcher = fileregexp.match(line)
            if dirmatcher != None:
                # line is a directory
                skip = topdir + dirmatcher.group(1) + "/"
                dirs = dirs + sort_results(skip)
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
        newpath = results[counter].replace(basepath, '', 1)
        if newpath.find('/') > -1:
            # $newpath is directory and becomes the top one

            matcher = re.match('\A([^/]*/)', newpath)
            newpath = matcher.group(1)

            # do not add padding for the top level directory

            cutnewpath = newpath[:-1]

            if not basepath == '/':
                escapeddir = urllib.quote(basepath + cutnewpath)
                if playlistmode == 1:
                
                    # Browse-window of playlist editor
                    
                    print "<table><tr><td align='left'>"
                    print "<strong><a href='mBrowse.py?mode=playlist&dir=" + \
                        escapeddir + "&amp;playlist=" + playlist + \
                        "' >" + cgi.escape(cutnewpath) + \
                        "</a></strong>"
                    print "<td align='right'><a href='editplaylist.py?" + \
                        "playlist=" + playlist + "&deldir=" + escapeddir + \
                        "'>Delete</a></td>"
                    print "</tr></table>"

                elif playlistmode == 2:

                    # Search-window of playlist-editor
                
                    print "<table><tr><td align='left'>"
                    print "<strong><a href='mBrowse.py?mode=playlist&dir=" + \
                        escapeddir + "&amp;playlist=" + playlist + \
                        "' >" + cgi.escape(cutnewpath) + \
                        "</a></strong>"
                    print "<td align='right'><a href='editplaylist.py?" + \
                        "playlist=" + playlist + "&adddir=" + escapeddir + \
                        "' >Add</a></td>"
                    print "</tr></table>"
                    
                else:
                    print "<strong><a href='mBrowse.py?dir=" + escapeddir + \
                        "'>" + cgi.escape(cutnewpath) + "</a></strong>"
                newpath = basepath + newpath
            else:
                escapeddir = urllib.quote("/" + cutnewpath)
                if playlistmode == 1:
                    print "<table><tr><td align='left'>"
                    print "<strong><a href='mBrowse.py?mode=playlist&dir=" + \
                        escapeddir + "&amp;playlist=" + playlist + \
                        "' >" + cgi.escape(cutnewpath) + \
                        "</a></strong>"
                    print "<td align='right'><a href='editplaylist.py?" + \
                        "playlist=" + playlist + "&deldir=" + escapeddir + \
                        "'>Delete</a></td>"
                    print "</tr></table>"
                elif playlistmode == 2:
                    print "<table ><tr><td align='left'>"
                    print "<strong><a href='mBrowse.py?mode=playlist&dir=" + \
                        escapeddir + "&amp;playlist=" + playlist + \
                        "' >" + cgi.escape(cutnewpath) + \
                        "</a></strong>"
                    print "<td align='right'><a href='editplaylist.py?" + \
                        "playlist=" + playlist + "&adddir=" + escapeddir + \
                        "' >Add</a></td>"
                    print "</tr></table>"
                else:
                    print "<strong><a href='mBrowse.py?dir=" + escapeddir + \
                        "'>" + cgi.escape(cutnewpath) + "</a></strong>"
                newpath = "/" + newpath

            # Call listdir recursive, then quit padding with <div>

            print "<div style='padding-left: 1em;'>"
            counter = listdir(newpath, counter, cssclass, playlistmode, playlist)
            print "</div>"

        else:

            # $newpath is a regular file without leading directory

            playlistContents = getPlaylistContents(playlist)
            historyList = history(playlist)

            while counter < len(results) and \
                (os.path.dirname(results[counter]) + "/" == basepath or os.path.dirname(results[counter]) == basepath):

                # Print all filenames in basepath

                filename = os.path.basename(results[counter])
                matcher = re.match('(.*)\.([^\.]+)\Z', filename)
                nameonly = matcher.group(1)
                escapedfile = urllib.quote(basepath + filename)

                # $cssclass changes to give each other file
                # another color

                if cssclass == 'file':
                    cssclass = 'file2'
                else:
                    cssclass = 'file'

                print "<table><tr>"
                print "<td align='left'><a href='mInfo.py?file=" + \
                    escapedfile + "' class='" + cssclass + "'>" + \
                    cgi.escape(nameonly) + "</a></td>"
                if playlistmode == 1:
                    print "<td align='right'><a href='editplaylist.py?" + \
                    "playlist=" + playlist + "&delfile=" + escapedfile + \
                        "' class='" + cssclass + "'>Delete</a></td>"
                elif playlistmode == 2:
                    print "<td align='right'><a href='editplaylist.py?" + \
                    "playlist=" + playlist + "&amp;addfile=" + escapedfile + \
                        "'  class='" + cssclass + "'>Add</a></td>"
                else:
                    """ 
                    (mayVote, reason) = may_vote(basepath+filename, playlist, playlistContents, historyList)
                    if os.path.exists(myconfig['basedir']) and mayVote:
                        print "<td align='right'><a href='mHome.py" + \
                        "?vote=" + escapedfile + "' class='" + cssclass + \
                        "' >W&uuml;nschen</a></td>"
                    elif not mayVote:
                        print "<td align='right'><span class='" + cssclass + "' " +\
                              " style='font-style: italic;' '>" + reason + "</span></td>"
                    else:
                    """
                    print "<td></td>"
                print "</tr></table>\n"
                counter = counter + 1

    return counter

def history(playlistName=None):
    if playlistName is None or len(playlistName) == 0:
        playlistFile = open(myconfig['basedir'] + 'playlist')
        playlistName = playlistFile.readline().rstrip()
        playlistFile.close()
    done = []
    historyPath = myconfig['savedir'] + 'logs/' + playlistName
    historyFile = open( historyPath, 'r' )
    lines = historyFile.readlines( )
    lines.reverse()

    if lines is None:
        return []

    for line in lines:
        if line.find('DONE'):
            done.append(line)
            if len(done) >= 15:
                break
    historyFile.close()
    return done

def votes():
    votefile = open(myconfig['basedir'] + 'votes')
    lines = votefile.readlines( )
    votefile.close()
    return lines

def playlistBlocksVoting():
    novotes = 'false'
    try:
        novotes = myconfig['novotes']
    except:
        pass

    return novotes.lower() == 'true'

def getPlaylistContents(playlistName=None):
    if playlistName is None or len(playlistName) == 0:
        playlistFile = open(myconfig['basedir'] + 'playlist')
        playlistName = playlistFile.readline().rstrip()
        playlistFile.close()
    playlistPath = myconfig['savedir'] + 'lists/' + playlistName
    listfile = open( playlistPath )
    playlistContents = listfile.readlines();
    listfile.close()
    return playlistContents


def may_vote(f, playlist, playlistContents=None, historyList=None):
    exists = False

    # Check if playlist blocks voting
    if playlistBlocksVoting():
        return (False, "W&uuml;nschen ist im Moment gesperrt.")

    # Check if f is currently playing
    infoFile = file( myconfig['basedir'] + "/info" )
    currentfile = infoFile.readline( )
    infoFile.close()
    if currentfile.find(f) != -1:
        return (False, "L&auml;uft gerade")

    # Check if f is in currently voted files
    votelist = votes( )
    votematches = [ x for x in votelist if x.find(f) != -1]

    if len(votematches) > 0:
        # if f in votes
        return (False, "Schon gew&uuml;nscht")

    if playlistContents == None:
        playlistContents = getPlaylistContents()

    for playlistline in playlistContents:
        if playlistline.find(f) >= 0:
            exists = True
            break

    if not exists:
    # if not f in currentList
        return (False, "Nicht in Playlist")


    if len(votelist) >= 15:
        # if votes.length >= 15 return (true, "")
        return (True, None)

    if historyList == None:
        historyList = history( playlist )

    if historyList is not None:
        historyMatches = [ line for line in historyList[0:15-len(votelist)] if line.find(f) != -1 ]
        if len(historyMatches) > 0:
            # if f in history(0,15-votes.size) return (false, "Es ist noch nicht lang genug her, dass dieser Song gespielt wurde")
            return (False, "Lief gerade")

    # else return (true, "")
    return (True, None)

