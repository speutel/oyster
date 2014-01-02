#!/usr/bin/python
# -*- coding: UTF-8 -*
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

import config
myconfig = config.get_config()


def print_playlist(filename):
    title = re.sub('\A.*_', '', filename)
    encfile = urllib.quote(filename)

    if os.path.getsize(myconfig['savedir'] + '/lists/' + filename) == 0:
        isempty = " <span class='emptylist'>(empty)</span>"
    else:
        isempty = ''

    print "<div class='ui-grid-b'>"

    if filename == playlist and filename != 'default':
        print "<div class='ui-block-a'><i><a href='playlistinfo.py?list=" + encfile + "'>" + title + "</a></i></div>"
        print "<div class='ui-block-b'><strong class='ui-btn'>currently playing</strong></div>"
        print "<div class='ui-block-c'><a class='ui-btn' href='editplaylist.py?" + \
            "playlist=" + encfile + "' target='_top' data-role='button' data-icon='grid'>Edit</a></div>"
    elif filename != 'default':
        print "<div class='ui-block-a'>" + title + isempty + "</div>"
        print "<div class='ui-block-b'>"
        if oysterruns:
            print "<a href='playlists.py?action=loadlist&amp;" + "listname=" + encfile +\
                  "' data-role='button' data-icon='refresh'>Load</a>"
        print "</div>"
        print "<div class='ui-block-c'><a href='editplaylist.py?" + \
            "playlist=" + encfile + "' target='_top' data-role='button' data-icon='grid'>Edit</a></div>"
        print "</div><div class='ui-grid-b'>"
        print "<div class='ui-block-a'></div>"
        print "<div class='ui-block-b'><a href='playlists.py?action=move&amp;" + \
            "playlist=" + encfile + "' data-role='button' data-icon='gear'>Move/Rename</a></div>"
        print "<div class='ui-block-c'><a href='playlists.py?action=confirmdelete&amp;" + \
            "listname=" + encfile + "' data-role='button' data-icon='delete'>Delete</a></div>"

    print "</div>"

def confirmdelete():
    playlist = form['listname'].value
    enclist = urllib.quote(playlist)
    print "<h1>Should " + playlist + " be deleted?</h1>"
    print "<a href='playlists.py?action=delete&amp;listname=" + enclist + "'>Yes, delete it</a>"
    print "<br/>"
    print "<a href='playlists.py'>No, return to overview</a>"
    print "</body></html>"


def renameform(playlist):

    entries = os.listdir(myconfig['savedir'] + 'lists/')
    section = {}

    for entry in entries:
        if os.path.exists(myconfig['savedir'] + 'lists/' + entry) and entry.find('_') > -1:
            entry = re.sub('_.*', '', entry)
            section[entry] = 1;

    sections = ['Default']

    sectionkeys = section.keys()
    sectionkeys.sort()

    for section in sectionkeys:
        sections.append(section)

    title = re.sub('\A.*_', '', playlist)

    print "<h1>" + title + "</h1>"
    print "<h2>Move to another section</h2>"
    print "<div style='padding-left: 2em;'>"

    print "<form method='post' action='playlists.py' enctype='application/x-www-form-urlencoded'>"
    print "<input type='hidden' name='action' value='movelistsave'>"
    print "<input type='hidden' name='playlist' value='" + playlist + "'>"
    print "<input type='radio' name='sectiontype' value='existing' checked> " + \
            "in existing Section "

    print "<select name='existingsection'>"
    for existingsection in sections:
        print "<option value='" + existingsection + "'>" + existingsection + "</option>"
    print "</select><br/><br/>"

    print "<input type='radio' name='sectiontype' value='new'> " + \
            "in new Section <input type='text' name='newsection'>"
    print "<br/><br/>"
    print "<input type='submit' value='Move'>"
    print "</form>"

    print "</div><br/>"

    print "<h2>Rename</h2>"
    print "<div style='padding-left: 2em;'>"
    print "<form method='post' action='playlists.py' enctype='application/x-www-form-urlencoded'>"
    print "<input type='hidden' name='action' value='rename'>"
    print "<input type='hidden' name='playlist' value='" + playlist + "'>"
    print "<input type='textfield' name='newname'><br/><br/>"
    print "<input type='submit' value='Rename'>"
    print "</form></div>"
    sys.exit()


def listrename(oldname, newname):
    
    for dirname in ['blacklists/', 'lists/', 'logs/', 'scores/']:
        if os.path.exists(myconfig['savedir'] + dirname + oldname):
            os.rename(myconfig['savedir'] + dirname + oldname, \
            myconfig['savedir'] + dirname + newname)


import cgi
import fifocontrol
import cgitb
import sys
import os.path
import urllib
import re
import common
cgitb.enable()

_ = common.get_prefered_language()

basedir = myconfig['basedir']
savedir = myconfig['savedir']
form = cgi.FieldStorage()

if os.path.exists(myconfig['basedir']):
    oysterruns = 1
else:
    oysterruns = 0

import common
common.navigation_header("Playlists")

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

if form.has_key('playlist') and form.has_key('action') and form['action'].value == 'move':
    renameform(form['playlist'].value)

if form.has_key('action') and form['action'].value == 'rename' and \
    form.has_key('playlist') and form.has_key('newname'):
    if form['playlist'].value.find('_') > -1:
        section = re.sub('_.*\Z', '_', form['playlist'].value)
    else:
        section = ''
    listrename(form['playlist'].value, section + form['newname'].value)

# Move playlist to new or existing section

if form.has_key('action') and form['action'].value == 'movelistsave' and \
    form.has_key('sectiontype') and form.has_key('playlist'):

    newsection = ''
    
    if form['sectiontype'].value == 'existing' and form.has_key('existingsection'):
    
        if not form['existingsection'].value == 'Default':
            newsection = form['existingsection'].value + '_'

    elif form['sectiontype'].value == 'new' and form.has_key('newsection'):

        if form.has_key('newsection') and not form['newsection'].value == 'Default':
            newsection = form['newsection'].value + '_'
        
    onlyplaylist = re.sub('\A.*_', '', form['playlist'].value)
    
    listrename(form['playlist'].value, newsection + onlyplaylist)

entries = os.listdir(savedir + "lists/")
entries.sort()

files = []
section = {}

for entry in entries:
    if os.path.isfile(savedir + "lists/" + entry):
        files.append(entry)
        if entry.find('_') > -1:
            entry = re.sub('_.*','',entry)
            section[entry] = 1

if form.has_key('action') and form['action'].value == 'loadlist' and form.has_key('listname'):
    playlist = form['listname'].value
else:
    playlist = config.get_playlist()

print "<h1>" + _("Playlists") + "</h1>"

print "<tr><td colspan='6'><h1>Playlists</h1></td></tr>"

# Print default playlist

print "<div class='ui-grid-b'>"

if playlist == 'default':
    print "<div class='ui-block-a'><a href='playlistinfo.py?list=default'><i>default (All songs)</i></a></div>" + \
        "<div class='ui-block-b'><strong>currently playing</strong></div>"
else:
    print "<div class='ui-block-a'><a href='playlistinfo.py?list=default'>default (All songs)</a></div>"
    if oysterruns:
        print "<div class='ui-block-b'><a class='ui-btn' href='playlists.py?action=loadlist&amp;" + \
            "listname=default' data-role='button' data-icon='refresh'>Load</a></div>"

print "</div>"

for filename in files:
    if filename.find('_') == -1:
        print_playlist(filename)

# Print all sections

sectionkeys = section.keys()
sectionkeys.sort()

for section in sectionkeys:
    print "<h2>" + section + "</h2>"
    for filename in files:
        if filename.find(section + "_") == 0:
            print_playlist(filename)


if oysterruns:
    print "<form method='post' target='_top' action='editplaylist.py' " + \
        "enctype='application/x-www-form-urlencoded'>"
    print "<input type='hidden' name='action' value='addnewlist'/><input " + \
        "type='text' name='newlistname'/>"
    print "<input type='submit' name='.submit' value='New list' " + \
        "style='margin-left: 2em;'/ data-role='button' data-icon='plus'>"
    print "<div></div></form><br/>"
else:
    print "<p>To create a new list, start oyster first!</p><br/>"

print "<a href='configedit.py'>Configuration Editor</a>"

print "</body></html>"
