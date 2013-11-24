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

"""
Allows the user to specify regex-lines for files
which should not be played at random
"""

__revision__ = 1

import cgi
import config
import cgitb
import os.path
import urllib
import common
import re
cgitb.enable()

def print_blacklist ():

    "Opens current blacklist and prints each line"

    lineaffects = {}
    blacklistmatchers = {}

    if os.path.exists(myconfig['savedir'] + "blacklists/" + playlist):
        blacklist = open(myconfig['savedir'] + "blacklists/" + playlist)
        for line in blacklist.readlines():
            blacklistmatchers[line[:-1]] = re.compile(line.rstrip())
            line = line.replace(mediadir, '', 1)[:-1]
            lineaffects[line] = 0
        blacklist.close()

    listfile = open(myconfig['savedir'] + "lists/" + playlist)

    totalaffected = 0

    # Count affected files for each rule

    for line in listfile.readlines():
        isblacklisted = 0
        line = line.replace(mediadir, '', 1)[:-1]
        for key in blacklistmatchers.keys():
            if blacklistmatchers[key].search(line):
                isblacklisted = 1
                lineaffects[key] += 1
        if isblacklisted:
            totalaffected += 1

    listfile.close()

    blacklistlines = blacklistmatchers.keys()
    blacklistlines.sort()
    print "<table width='100%'>"
    for line in blacklistlines:
        escapedline = urllib.quote(line)
        print "<tr><td width='60%'>" + line + "</td>"
        print "<td width='25%' align='left'><a href='blacklist.py?" + \
            "action=test&amp;affects=" + escapedline + "'>Affects</a> (" + \
            str(lineaffects[line]) + ")</td>"
        print "<td width='15%' align='center'><a href='blacklist.py?" + \
            "action=delete&amp;affects=" + escapedline + \
            "'>Delete</a></td></tr>"

    print "</table>"

    print "<p><strong>Total files affected:</strong> " + \
        str(totalaffected) + "</p>"

def print_affects (affects):

    "Shows all files, which are affected by a blacklist-rule"

    affectresults = []

    # Add all matching lines to results

    if os.path.exists(myconfig['savedir'] + "lists/" + playlist):
        listfile = open (myconfig['savedir'] + "lists/" + playlist, 'r')
        for line in listfile.readlines():
            line = line.replace(mediadir, '', 1)[:-1]
            if re.compile(affects).search(line) != None:
                affectresults.append(line)
        listfile.close()

    # Sort results alphabetically

    if affectresults != []:
        affectresults.sort()
        common.results = affectresults
        common.listdir('/', 0,'file2')
    else:
        print "<p>No songs match these rule.</p>"

def add_to_blacklist (affects):

    "Appends a rule to the blacklist"

    blacklist = open(savedir + "blacklists/" + playlist, 'a')
    blacklist.write(affects + "\n")
    blacklist.close()

def delete_from_blacklist (affects):

    "removes a rule from the blacklist"

    os.system ("cp \"" + savedir + "blacklists/" + playlist + "\" " + \
        savedir + "blacklist.tmp")
    blacklist = open(savedir + "blacklist.tmp")
    newblacklist = open(savedir + "blacklists/" + playlist, 'w')
    for line in blacklist.readlines():
        if line[:-1] != affects:
            newblacklist.write(line)
    blacklist.close()
    newblacklist.close()
    os.unlink (savedir + "blacklist.tmp")

myconfig = config.get_config()
basedir = myconfig['basedir']
savedir = myconfig['savedir']
mediadir = myconfig['mediadir'][:-1]
form = cgi.FieldStorage()
playlist = config.get_playlist()

import mCommon
mCommon.navigation_header("Blacklists")

results = []

if form.has_key('affects') and form.has_key('action') \
    and form['action'].value == 'test':
    escaffects = cgi.escape(form['affects'].value)
else:
    escaffects = ''

# Create form

print "<form method='post' action='blacklist.py' " + \
    "enctype='application/x-www-form-urlencoded'>"
print "<fieldset class='searchform'>"
print "<legend class='searchform'>Add entries to blacklist</legend>"
print "<input id='searchfield' type='text' size='40' name='affects' value='" + escaffects + "'/>"
print "<input id='searchsubmit' type='submit' name='.submit' value='Go'/>"
print "<table id='searchoptions'><tr>"
print "<td><input type='radio' name='action' value='test' checked='checked'/> " + \
    "Test only</td></tr>"
print "<tr><td><input type='radio' name='action' value='add'/> " + \
    "Add to blacklist</td></tr>"
print "</table>"
print "</fieldset>"
print "</form>"

print "<p><a href='blacklist.py'>Show current blacklist</a></p>"

if form.has_key('action') and form.has_key('affects'):
    if form['action'].value == 'test':
        print_affects(form['affects'].value)
    elif form['action'].value == 'add':
        add_to_blacklist(form['affects'].value)
        print_blacklist()
    elif form['action'].value == 'delete':
        delete_from_blacklist(form['affects'].value)
        print_blacklist()
else:
    print_blacklist()

print "</body></html>"
