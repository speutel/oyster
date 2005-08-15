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

def print_playlist(playlist):
    title = re.sub('\A.*_', '', playlist)
    encfile = urllib.quote(playlist)

    print "<tr><td>" + title + "</td><td class='playlists'></td>"
    print "<td class='playlists'><a href='configedit.py?" + \
        "playlist=" + encfile + "'>Edit Config</a></td>"
    if playlist in configs and playlist != 'default':
        print "<td class='playlists'><a href='configedit.py?" + \
            "action=delete&amp;playlist=" + encfile + "'>Delete Config</a></td>"
    print "</tr>"


def configeditor(playlist):

    print "<h1>Editing configuration for playlist " + \
        cgi.escape(playlist) + "</h1>"

    # Start with builtin defaults
    workconfig = config.get_defaults()

    # Read global config
    if os.path.exists(savedir + "/config/default"):
        defaultconfig = config.get_values(savedir + "/config/default")
        for key in defaultconfig.keys():
            workconfig[key] = defaultconfig[key]
            
    if not playlist in configs:
        print "There was no configuration file found this playlist<br>"
        print "Default values taken from default configuration"
    else:
        # Read playlist-config
        plconfig = config.get_values(savedir + "/config/" + playlist)
        for key in plconfig.keys():
            workconfig[key] = plconfig[key]
        
    print "<form method='post' action='configedit.py' " + \
        "enctype='application/x-www-form-urlencoded'>"

    print "<input type='hidden' name='action' value='saveconfig'/>"
    print "<input type='hidden' name='playlist' value='" + \
        cgi.escape(playlist) + "'/>"

    if playlist == 'default':

        print "<h2>Basedir</h2>"
        print "<input type='text' name='basedir' value='" + \
            workconfig['basedir'] + "' size='50' maxlength='255'/>"

        print "<p class='configdescription'>" + \
            "Basedir tells oyster where it should put its dynamic files, " + \
            "the FIFOs it needs and the log and infofile.</p>"


        print "<h2>Savedir</h2>"
        print "<input type='text' name='savedir' value='" + \
            workconfig['savedir'] + "' size='50' maxlength='255'/>"
            
        print "<p class='configdescription'>" + \
            "Savedir tells oyster where to save files that it needs for " + \
            "more than one session, for example the votes you did and " + \
            "the playlists you save</p>"


        print "<h2>Mediadir</h2>"
        print "<input type='text' name='mediadir' value='" + \
            workconfig['mediadir'] + "' size='50' maxlength='255'/>"
            
        print "<p class='configdescription'>" + \
            "mediadir is where your files are. " + \
            "If you don\"t give oyster a playlist in the commandline, " + \
            "it will search your files under this directory and build a " + \
            "default playlist from these.</p>"

        print "<h2>Theme</h2>"
        print "<select name='theme'>"
        for theme in os.listdir(savedir + 'themes/'):
            if theme[0] != '.':
                if theme == workconfig['theme']:
                    print "<option selected='selected'>" + theme + "</option>"
                else:
                    print "<option>" + theme + "</option>"
        print "</select>"

        print "<p class='configdescription'>" + \
            "Specifies the chosen theme.</p>"
        
        print "<h2>coverfilenames</h2>"
        print "<input type='text' name='coverfilenames' value='" + \
            workconfig['coverfilenames'] + "' size='50' maxlength='255'/>"
        
        print "<p class='configdescription'>" + \
            "coverfilenames is a comma-seperated list, which lists " + \
            "all possible names for album-covers relative to the album. " + \
            "Use ${album} to reference in filenames and ${albumus} if" + \
            "you like to use underscores instead of whitespaces.</p>"
            

        print "<h2>coverwidth</h2>"
        print "<input type='text' name='coverwidth' value='" + \
            workconfig['coverwidth'] + "' size='4' maxlength='10'/>"
            
        print "<p class='configdescription'>" + \
            "coverwidth is the width of the cover displayed in" + \
            "File Information</p>"
            
    print "<h2>Maxscored</h2>"
    print "<input type='text' name='maxscored' value='" + \
        workconfig['maxscored'] + "' size='8' maxlength='8'/>"

    print "<p class='configdescription'>" + \
    "Max Scored sets the maximum number of saved votes " + \
    "(oyster chooses songs at random from this list)</p>"


    print "<h2>Voteplay</h2>"
    print "<input type='text' name='voteplay' value='" + \
        workconfig['voteplay'] + "' size='3' maxlength='3'/>"

    print "<p class='configdescription'>" + \
    "voteplay sets the probability in percent that one " + \
    "of the files from lastvotes is played.</p>"

    print "<h2>Len_Nextfiles</h2>"
    print "<input type='text' name='len_nextfiles' value='" + \
        workconfig['len_nextfiles'] + "' size='2' maxlength='2'/>"

    print "<p class='configdescription'>" + \
    "How many files oyster shows in advance</p>"

    print "<input type='submit' value='Save Config'/>"

    print "</form></body></html>"

    sys.exit()


def saveconfig(playlist):

    "Writes config values to the config file"

    playlist = os.path.basename(playlist)

    if not ((os.path.exists(savedir + "config/" + playlist) and \
        os.access(savedir + "config/" + playlist, os.W_OK)) or \
        os.access(savedir + "config/", os.W_OK)):

        print "Sorry, Oyster does not have the permission to write the " + \
            "configuration to " + cgi.escape(savedir + "config/" + playlist)
        print "</body></html>"
        sys.exit()

    if os.path.exists(savedir + "config/" + playlist):

        # File already exists, rename it first
    
        os.rename(savedir + "config/" + playlist, \
            savedir + "config/" + playlist + ".old")
        oldconfig = open(savedir + "config/" + playlist + ".old")
        configfile = open(savedir + "config/" + playlist, 'w')

        writtenkeys = []
        keymatcher = re.compile('\A([^#]\w*)=')

        for line in oldconfig.readlines():
            linematch = keymatcher.match(line[:-1])
            if linematch != None:
                key = linematch.group(1)
                if form.has_key(key):
                    configfile.write(key + "=" + form[key].value + "\n")
                    writtenkeys.append(key)
                else:
                    configfile.write(line)
            else:
                configfile.write(line)

        # Check, if any values did not exist in the original config

        for key in form.keys():
            if key not in ['action', 'playlist'] + writtenkeys:
                configfile.write(key + "=" + form[key].value + "\n")
                
        configfile.close()
        oldconfig.close()

        os.remove(savedir + "config/" + playlist + ".old")
    else:

        # There was no existing config, simply write a new one
    
        configfile = open(savedir + "config/" + playlist, 'w')
        for key in form.keys():
            if key not in ['action', 'playlist']:
                configfile.write(key + "=" + form[key].value + "\n")
        configfile.close()

    # If playlist is currently running, reload it

    if playlist == config.get_playlist():
        fifocontrol.do_action('loadlist', playlist) 
    

__revision__ = 1

import cgi
import config
import cgitb
import sys
import os.path
import urllib
import common
import re
import fifocontrol
cgitb.enable()

myconfig = config.get_config()
basedir = myconfig['basedir']
savedir = myconfig['savedir']
form = cgi.FieldStorage()

common.navigation_header();

playlists = os.listdir(savedir + "lists/")
configs = os.listdir(savedir + "config/")

if form.has_key('action'):
    if form['action'].value == 'saveconfig' and form.has_key('playlist'):
        saveconfig(form['playlist'].value)
    elif form['action'].value == 'delete' and form.has_key('playlist'):
        os.unlink(savedir + "config/" + os.path.basename(form['playlist'].value))
elif form.has_key('playlist'):
    configeditor(form['playlist'].value)

playlists = os.listdir(savedir + "lists/")
configs = os.listdir(savedir + "config/")

files = []
sections = []

for entry in playlists:
    if os.path.isfile(savedir + "lists/" + entry):
        files.append(entry)
        if entry.find('_') > -1:
            entry = re.sub('_.*', '', entry)
            if entry not in sections:
                sections.append(entry)

sections.sort()

print "<table width='100%' style='margin-bottom: 2em;'>"

print "<tr><td colspan='5'><h2>Configuration Editor</h2></td></tr>"

# Print playlists without a section

for filename in files:
    if filename.find('_') == -1:
        print_playlist(filename)

# Print all sections

for section in sections:
    print "<tr><td colspan='5'><h2>" + section + "</h2></td></tr>"
    for filename in files:
        if filename.find(section + "_") == 0:
            print_playlist(filename)

print "</table>"

print "</body></html>"
