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

import taginfo
import urllib
import re
import cgitb
cgitb.enable()

import config
myconfig = config.get_config()
basedir = myconfig['basedir']
mediadir = myconfig['mediadir'][:-1]
import cgi
form = cgi.FieldStorage()

playlist = config.get_playlist()

import common
common.navigation_header()

try:
    soundfile = form['file'].value
except KeyError:
    soundfile = ''

import fifocontrol
if 'action' in form:
    fifocontrol.do_action(form['action'].value, soundfile)

import os.path
import sys
if not os.path.exists(mediadir + soundfile):
    print "<h1>Error!</h1>"
    print "<p>File <strong>" + soundfile + "</strong> could not be found.</p>"
    print "</body></html>"
    sys.exit()

if os.path.exists(myconfig['basedir']):
    oysterruns = 1
else:
    oysterruns = 0

print "<p><a href='browse.py?dir=/'>Mediadir</a>"

subdir = soundfile.replace(mediadir, '', 1)
subdir = os.path.dirname(subdir)
soundfileonly = os.path.basename(soundfile)
dirs = subdir.split('/')
incdir = ''
for partdir in dirs:
    escapeddir = urllib.quote(incdir + partdir)
    print "<a href='browse.py?dir=" + escapeddir + "'>" + partdir + "</a> / "
    incdir = incdir + partdir + "/"

print cgi.escape(soundfileonly) + "</p><br clear='all'/>"

isblacklisted = 0
if os.path.exists(myconfig['savedir'] + "blacklists/" + playlist):
    blacklist = open(myconfig['savedir'] + "blacklists/" + playlist)
    for rule in blacklist.readlines():
        if re.match('.*' + rule[:-1] + '.*', soundfile):
            isblacklisted = 1
    blacklist.close()

escapedfile = urllib.quote(soundfile)

if not os.access(mediadir + soundfile, os.R_OK):
    print "<h1>Sorry, Oyster does not have the permission to read this file!</h1>"
    print "</body></html>"
    sys.exit()

(mayVote, reason) = common.may_vote(soundfile, None)

print "<p>"
if oysterruns and mayVote:
    print "<span class='file'><a class='file' href='home.py?vote=" + escapedfile + "' >Vote this song</a></span>"
elif oysterruns and not mayVote:
    print "<span class='file' style='font-style: italic;' '>" + reason + "</span>"
else:
    print ""
print "</p>"

print "<p>"

if isblacklisted:
    print "<span class='blacklisted'>This song is blacklisted</span>"
else:
    regexfile = urllib.quote("^" + re.escape(soundfile) + "$")
    print "<a class='file' href='blacklist.py?affects=" + regexfile + "&amp;action=add'>Add this song to blacklist</a>"
print "</p>"

regexfile = urllib.quote("^" + re.escape(soundfile) + "$")

tag = taginfo.get_tag(mediadir + soundfile)

timesplayed = 0
logmatcher = re.compile('\A[0-9]{4}[0-9]{2}[0-9]{2}\-[0-9]{2}[0-9]{2}[0-9]{2} ([^ ]*) (.*)\Z')
log = open(myconfig['savedir'] + "logs/" + playlist)
for line in log.readlines():
    matcher = logmatcher.match(line[:-1])
    if matcher is not None and matcher.group(2).find(soundfile) > -1 and matcher.group(1) == 'DONE':
        timesplayed += 1

log.close()

albumdir = os.path.dirname(mediadir + soundfile) + "/"
coverdata = common.get_cover(albumdir, "200")

print "<table border='0'>"
if 'title' in tag:
    print "<tr><td class='fileinfo'>Title: </td><td>" + tag['title']

    if 'artist' in tag and 'title' in tag:
        print "<a class='file' href='lyrics.py?artist=" + urllib.quote(tag['artist']) + \
              "&amp;song=" + urllib.quote(tag['title']) + "'> (Songtext)</a>"

    print "</td></tr>"

if 'artist' in tag:
    print "<tr><td class='fileinfo'>Artist: </td><td>"
    print "<a href='search.py?searchtype=normal&amp;playlist=current&amp;" + \
        "search=" + urllib.quote(tag['artist']) + "' title='Search for " + \
        "this artist' class='file'>" + tag['artist'] + "</a></td></tr>"

if coverdata != '':
    print "<tr><td class='fileinfo'>Cover: </td><td>" + coverdata + "</td></tr>"

tagtuple = (
    ('Album: ', 'album'),
    ('Track: ', 'track'),
    ('Year: ', 'year'),
    ('Genre: ', 'genre'),
    ('Comment: ', 'comment'),
    ('Format: ', 'format'),
    ('Length: ', 'playtime')
)

for line in tagtuple:
    if line[1] in tag:
        print "<tr><td class='fileinfo'>" + line[0] + "</td>" + \
            "<td>" + tag[line[1]] + "</td></tr>"

print "<tr><td colspan='2'>&nbsp;</td></tr>"
print "<tr><td class='fileinfo'>Played: </td><td>" + str(timesplayed) + " times</td></tr>"
print "<tr><td class='fileinfo'>Score: </td>"
print "<td><a href='fileinfo.py?action=scoredown&amp;file=" + escapedfile + "' title='Score down'>"
print "<img src='themes/" + myconfig['theme'] + "/scoredownfile.png' border='0' alt='-'/></a> "
print "<strong>" + str(tag['score']) + "</strong>"
print " <a href='fileinfo.py?action=scoreup&amp;file=" + escapedfile + "' title='Score up'>"
print "<img src='themes/" + myconfig['theme'] + "/scoreupfile.png' border='0' alt='+'/></a></td></tr>"

print "</table>"

print "</body></html>"
