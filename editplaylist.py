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

import cgi
import common
import config
import fifocontrol
import cgitb
import sys
import os.path
import urllib
cgitb.enable()


def print_frameset():
    
    """Generates a frameset for the playlist editor"""
    
    print "Content-Type: text/html; charset=" + myconfig['encoding'] + "\n"
    print """
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN"
   "http://www.w3.org/TR/html4/frameset.dtd">
<html>
<head>
"""
    print"<title>Edit Playlist " + playlist + "</title>"
    print"<link rel='shortcut icon' href='themes/default/favicon.png'>"
    print"</head>"
    print"<frameset rows='50,*'>"
    print"  <frame src='editplaylist.py?mode=title&playlist=" + urllib.quote(playlist) + "' name='title'>"
    print"  <frameset cols='*,*'>"
    print"   <frame src='editplaylist.py?mode=edit&playlist=" + urllib.quote(playlist) + "' name='playlist'>"
    print"   <frame src='browse.py?mode=editplaylist&playlist=" + urllib.quote(playlist) + "' name='browse'>"
    print"  </frameset>"
    print"    <noframes>"
    print"	<p>"
    print"   Your browser does not seem to support display of frames."
    print"	</p>"
    print"  </noframes>"
    print"</frameset>"
    print"</html>"


def print_title():
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
    print "<form method='post' target='_top' action='index.html'><input type='hidden' name='view' value='playlists'>"
    print "<p align='center'><b>Editing playlist " + playlist + "</b> " +\
        "<input type='submit' value='Done'></p></form>"
    print "</body></html>"
    
myconfig = config.get_config()
basedir = myconfig['basedir']
savedir = myconfig['savedir']
mediadir = myconfig['mediadir'][:-1]
form = cgi.FieldStorage()

if 'action' in form and form['action'].value == 'addnewlist' and 'newlistname' in form:
    fifocontrol.do_action('addnewlist', form['newlistname'].value)
        
if 'playlist' in form:
    playlist = form['playlist'].value
elif 'newlistname' in form:
    playlist = form['newlistname'].value
else:
    common.navigation_header(title="Oyster-GUI")
    print "<p>You did not specify a name for the playlist.</p>"
    print "<p>Please press the <i>Back</i> button in your browser and try again.</a></p>"
    common.html_footer()
    sys.exit()

if playlist == 'default':
    common.navigation_header(title="Oyster-GUI")
    print "<p>It is not allowed to edit the default playlist.</p>"
    common.html_footer()
    sys.exit()

if not 'mode' in form and not 'delfile' in form and not 'deldir' in form and not 'addfile' in form\
        and not 'adddir' in form:
    print_frameset()
    sys.exit()
elif 'mode' in form and form['mode'].value == 'title':
    print_title()
    sys.exit()

# Starting from here: mode == edit

common.html_header(title="Oyster-GUI")

allfiles = []
playlistfile = open(savedir + "lists/" + playlist)
for line in playlistfile.readlines():
    line = line.replace(mediadir, '', 1)
    allfiles.append(line[:-1])
playlistfile.close()

# Delete a single file

if 'delfile' in form:
    allfiles.remove(form['delfile'].value)

# Delete a complete directory

if 'deldir' in form:
    tmpfiles = []
    for tmpfile in allfiles:
        if tmpfile.find(form['deldir'].value) != 0:
            tmpfiles.append(tmpfile)
    allfiles = tmpfiles

# Add a single file

if 'addfile' in form:
    if form['addfile'].value not in allfiles:
        allfiles.append(form['addfile'].value)

# Add a complete directory

filetypes = myconfig['filetypes'].lower().split(',')

if 'adddir' in form:
    for root, dirs, files in os.walk(mediadir + form['adddir'].value, topdown=False):
        for name in files:
            if name[name.rfind(".")+1:].lower() in filetypes:
                root = root.replace(mediadir, '', 1)
                if os.path.join(root, name).rstrip() not in allfiles:
                    allfiles.append(os.path.join(root, name).rstrip())
        

allfiles.sort()

if 'addfile' in form or 'adddir' in form or 'delfile' in form or 'deldir' in form:
    playlistfile = open(savedir + "lists/" + playlist, "w")
    for curfile in allfiles:
        playlistfile.write(mediadir + curfile + "\n")
    playlistfile.close()

import common
common.results = allfiles
allfiles = common.sort_results('/')

common.listdir('/', 0, 'file2', 1, playlist)

common.html_footer()
