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

def print_playlist(file):
    title = re.sub('\A.*_','',file)
    encfile = urllib.quote(file)

    if file == playlist and file != 'default':
        print "<tr><td><i>" + title + "</i></td><td class='playlists'><strong>currently playing</strong></td>"
        print "<td class='playlists'><a href='editplaylist.py?action=edit&amp;" + \
            "playlist=" + encfile + "'>Edit</a></td><td></td></tr>"
    elif file != 'default':
        print "<tr><td>" + title + "</td><td class='playlists'>"
        if oysterruns:
            print "<a href='playlists.py?action=loadlist&amp;" + \
                "listname=" + encfile + "'>Load</a>"
        print "</td>"
        print "<td class='playlists'><a href='editplaylist.py?action=edit&amp;" + \
            "playlist=" + encfile + "'>Edit</a></td>"
        print "<td class='playlists'><a href='editplaylist.py?action=move&amp;" + \
            "playlist=" + encfile + "'>Move/Rename</a></td>"
        print "<td class='playlists'><a href='playlists.py?action=confirmdelete&amp;" + \
            "listname=" + encfile + "'>Delete</a></td></tr>"

def confirmdelete():
    playlist = form['listname'].value
    enclist = urllib.quote(playlist)
    print "<h1>Should " + playlist + " be deleted?</h1>"
    print "<a href='playlists.py?action=delete&amp;listname=" + enclist + "'>Yes, delete it</a>"
    print "<br/>"
    print "<a href='playlists.py'>No, return to overview</a>"
    print "</body></html>"


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

myconfig = config.get_config('oyster.conf')
basedir = myconfig['basedir']
savedir = myconfig['savedir']
form = cgi.FieldStorage()

if os.path.exists(myconfig['basedir']):
    oysterruns = 1
else:
    oysterruns = 0

common.navigation_header();

if form.has_key('action') and (form.has_key('listname') or form.has_key('newlistname')):
    if form['action'].value == 'confirmdelete':
        confirmdelete()
        sys.exit()
    else:
        if form.has_key('listname'):
            file = form['listname'].value
        else:
            file = form['newlistname'].value
        fifocontrol.do_action(form['action'].value, file)

entries = os.listdir(savedir + "lists/")

files = []
section = {}

for entry in entries:
    if os.path.isfile(savedir + "lists/" + entry):
        files.append(entry)
        if entry.find('_') > -1:
            entry = re.sub('_.*','',entry)
            section[entry] = 1

playlist = ''

if form.has_key('action') and form['action'].value == 'loadlist' and form.has_key('listname'):
    playlist = form['listname'].value
else:
    playlist = config.get_playlist()

print "<table width='100%' style='margin-bottom: 2em;'>"

print "<tr><td colspan='5'><h2>Default</td></tr>"

# Print playlists without a section

if playlist == 'default':
    print "<tr style='height:3em;'><td><i>default (All songs)</i></td>" + \
        "<td class='playlists' colspan='4'><strong>currently playing</strong></td>"
    print "</tr>"
else:
    print "<tr style='height:3em;'><td>default (All songs)</td>" + \
        "<td class='playlists'>"
    if oysterruns:
        print "<a href='playlists.py?action=loadlist&amp;" + \
            "listname=default'>Load</a>"
    print "</td><td></td><td></td><td></td></tr>"

for file in files:
    if file.find('_') == -1:
        print_playlist(file)

# Print all sections

sectionkeys = section.keys()
sectionkeys.sort()

for section in sectionkeys:
    print "<tr><td colspan='5'><h2>" + section + "</h2></td></tr>"
    for file in files:
        if file.find(section + "_") == 0:
            print_playlist(file)

print "</table>"

print "<form method='post' action='/oyster/playlists.py' enctype='application/x-www-form-urlencoded'>"
print "<input type='hidden' name='action' value='addnewlist'><input type='text' name='newlistname' >"
print "<input type='submit' name='.submit' value='Create new list' style='margin-left: 2em;'>"
print "<div></div></form>"
