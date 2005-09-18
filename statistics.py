#!/usr/bin/python
# -*- coding: ISO-8859-1 -*-

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
import config
import taginfo
import cgitb
import urllib
import common
import re
import os.path
cgitb.enable()

def get_blacklisted():

    # Counts all files, which are affected by a blacklist-rule

    count = 0
    affectmatchers = []

    if os.path.exists(myconfig['savedir'] + "blacklists/" + playlist):
        blacklist = open (myconfig['savedir'] + "blacklists/" + playlist)
        for line in blacklist.readlines():
            affectmatchers.append(re.compile('.*' + line[:-1] + '.*'))
        blacklist.close()

    listfile = open (myconfig['savedir'] + "lists/" + playlist)

    for line in listfile.readlines():
        isaffected = 0
        line = line.replace(mediadir, '', 1)[:-1]
        for affectmatcher in affectmatchers:
            if affectmatcher.match(line):
                isaffected = 1
        if isaffected:
            count = count + 1
    listfile.close()

    return count

def print_songs (header, filearray):

    cssclass = 'file2'

    print "<table width='100%'>"
    print "<tr><th align='left'>Song</th><th>" + header + "</th></tr>"

    # for every song in mostplayed
    #  print artist/title
    filematcher = re.compile('\A(.*)\,\ ([A-Z0-9]*)\Z')
    for line in filearray:
        matcher = filematcher.match(line)
        filename = matcher.group(1)
        reason = matcher.group(2)
        displayname = taginfo.get_tag_light(filename)
        filename = filename.replace(mediadir, '', 1)
        # (does not turn up in oyster-gui)
        escapedfilename = urllib.quote(filename)

        # switch colors
        if cssclass == 'file':
            cssclass = 'file2'
        else:
            cssclass = 'file'

        print "<tr><td>"
        
        if oysterruns:
            print "<a href='oyster-gui.py?action=enqueue&amp;file=" + escapedfilename + "' target='curplay' " + \
            "title='Enqueue'><img src='themes/" + myconfig['theme'] + "/enqueue" + cssclass + ".png'" +\
            "border='0' alt='Enqueue'/></a>"
        
        print "<a class='" + cssclass + "' href='fileinfo.py?" + \
        "file=/" + escapedfilename + "'>" + displayname + "</a></td>"
        print "<td class='"  + cssclass + "' align='center'>" + reason + "</td></tr>\n"
    print "</table>"

common.navigation_header()

myconfig = config.get_config()
mediadir = myconfig['mediadir'][:-1]
form = cgi.FieldStorage()
playlist = config.get_playlist()

# Check if oyster is started

if os.path.exists(myconfig['basedir']):
    oysterruns = 1
else:
    oysterruns = 0

# Load logfile into permanent array

logfile = open (myconfig['savedir'] + "logs/" + playlist)
log = logfile.readlines()
logfile.close()

lastplayed = []  # The last 10 played songs
mostplayed = []  # The "Top 10"
timesplayed = {} # Stores, how often a file has been played

votedfiles = randomfiles = scoredfiles = 0

check = '' # Check, if a file was blacklisted before counting it
logmatcher = re.compile('\A[0-9]{8}\-[0-9]{6}\ ([^\ ]*)\ (.*)\Z')

for line in log:
    matcher = logmatcher.match(line[:-1])
    if matcher != None:
        playreason = matcher.group(1)
        filename = matcher.group(2)

        # second turn: if file is checked and not blacklisted,
        # add it to the last played files.
        if playreason != 'BLACKLIST' and check != '':
            lastplayed.append(check)

        # never more than 10 entries
        if len(lastplayed) > 9:
            lastplayed.pop(0)

        # add files to the appropriate counters
        check = ''
        if playreason == 'DONE':
            if timesplayed.has_key(filename):
                timesplayed[filename] = timesplayed[filename] + 1
            else:
                timesplayed[filename] = 1
        elif playreason == 'VOTED':
            votedfiles = votedfiles + 1
            check = filename + ", " + playreason
        elif playreason == 'PLAYLIST':
            randomfiles = randomfiles + 1
            check = filename + ", " + playreason
        elif playreason == 'SCORED':
            scoredfiles = scoredfiles + 1
            check = filename + ", " + playreason
        elif playreason == 'ENQUEUED':
            check = filename + ", " + playreason

# Get the maximum value for $maxplayed

maxplayed = 0   # How often the Top-1-Song has been played

for filename in timesplayed.keys():
    if timesplayed[filename] > maxplayed:
        maxplayed = timesplayed[filename]

# Put the Top-10-Songs in mostplayed
# inefficient ... someone got a better idea? :)
counter = 10
while maxplayed > 0 and counter > 0:
    for filename in timesplayed.keys():
        if timesplayed[filename] == maxplayed and counter > 0:
            mostplayed.append(filename + ", " + str(timesplayed[filename]))
            counter -= 1
    maxplayed -= 1

totalfilesplayed = votedfiles + randomfiles + scoredfiles

# Print the collected data

print "<h1>Most played songs</h1>"

print_songs("Times played", mostplayed)

# Recently played songs

print "<h1>Recently played songs</h1>"

print_songs("Playreason", lastplayed)

# Some numbers

print "<h1>Some numbers</h1>"

totalfiles = 0
for line in open(myconfig['savedir'] + "lists/" + playlist):
    totalfiles += 1

print "<table width='100%'>"
print "<tr><td><strong>Total files in playlist</strong></td><td>" + str(totalfiles) + "</td></tr>"
print "<tr><td><strong>Files blacklisted</strong></td><td>" + str(get_blacklisted()) + "</td></tr>"
print "<tr><td><strong>Total files played</strong></td><td>" + str(totalfilesplayed) + "</td></tr>"
print "<tr><td><strong>Files played because of vote</strong></td><td>" + str(votedfiles) + "</td></tr>"
print "<tr><td><strong>Files played because of scoring</strong></td><td>" + str(scoredfiles) + "</td></tr>"
print "<tr><td><strong>Files played from playlist at random</strong></td><td>" + str(randomfiles) + "</td></tr>"
print "<tr><td><strong>Ratio Scoring/Random (should be ~ " + str(myconfig['voteplay']) + ")</strong></td>"
if scoredfiles + randomfiles == 0:
    print "<td>0</td></tr>"
else:
    print "<td>" + str((scoredfiles*100)/(scoredfiles+randomfiles)) + "</td></tr>"
print "</table>"

print "</body></html>"
