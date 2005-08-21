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

def print_frameset ():
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
    print"  <frame src='editplaylist.py?mode=title&playlist=" + playlist + "' name='title'>"
    print"  <frameset cols='*,*'>"
    print"   <frame src='editplaylist.py?mode=edit&playlist=" + playlist + "' name='playlist'>"
    print"   <frame src='browse.py?mode=playlist&playlist=" + playlist + "' name='browse'>"
    print"  </frameset>"
    print"    <noframes>"
    print"	<p>"
    print"   Your browser does not seem to support display of frames."
    print"	</p>"
    print"  </noframes>"
    print"</frameset>"
    print"</html>"

def print_title ():
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
    print "<p align='center'><b>Editing playlist " + form['playlist'].value + "</b> <a href='index.html' target='_top'>Done</a></p>"
    print "</body></html>"
    
myconfig = config.get_config()
basedir = myconfig['basedir']
savedir = myconfig['savedir']
mediadir = myconfig['mediadir'][:-1]
form = cgi.FieldStorage()

if form.has_key('playlist'):
    playlist = form['playlist'].value
else:
    sys.exit()

if not form.has_key('mode') and not form.has_key('delfile') \
    and not form.has_key('deldir') and not form.has_key('addfile') \
    and not form.has_key('adddir'):
    print_frameset()
    sys.exit()
elif form.has_key('mode') and form['mode'].value == 'title':
    print_title()
    sys.exit()

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

allfiles = []
playlistfile = open (savedir + "lists/" + playlist)
for line in playlistfile.readlines():
    line = line.replace(mediadir, '', 1)
    allfiles.append(line[:-1])
playlistfile.close()

# Delete a single file

if form.has_key('delfile'):
    allfiles.remove(form['delfile'].value)

# Delete a complete directory

if form.has_key('deldir'):
    tmpfiles = []
    for tmpfile in allfiles:
        if tmpfile.find(form['deldir'].value) != 0:
            tmpfiles.append(tmpfile)
    allfiles = tmpfiles

# Add a single file

if form.has_key('addfile'):
    if form['addfile'].value not in allfiles:
        allfiles.append(form['addfile'].value)

# Add a complete directory

if form.has_key('adddir'):
    for root, dirs, files in os.walk(mediadir + form['adddir'].value, topdown=False):
        for name in files:
            if name[name.rfind(".")+1:] in ['mp3','ogg']:
                root = root.replace(mediadir, '', 1)
                if os.path.join(root, name).rstrip() not in allfiles:
                    allfiles.append(os.path.join(root, name).rstrip())
        

allfiles.sort()

if form.has_key('addfile') or form.has_key('adddir') or \
    form.has_key('delfile') or form.has_key('deldir'):
    playlistfile = open (savedir + "lists/" + playlist, "w")
    for curfile in allfiles:
        playlistfile.write(mediadir + curfile + "\n")
    playlistfile.close()

common.results = allfiles
allfiles = common.sort_results('/')

common.listdir('/', 0, 'file2', 1, playlist)
