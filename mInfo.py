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

import mCommon
mCommon.navigation_header()

try:
    soundfile = form['file'].value
except KeyError:
    soundfile = ''

import fifocontrol
if form.has_key('action'):
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

print "<p><a href='mBrowse.py?dir=/'>Mediadir</a>"  

subdir = soundfile.replace(mediadir,'',1)
subdir = os.path.dirname(subdir)
soundfileonly = os.path.basename(soundfile)
dirs = subdir.split('/')
incdir = ''
for partdir in dirs:
    escapeddir = urllib.quote(incdir + partdir)
    print "<a href='mBrowse.py?dir=" + escapeddir +"'>" + partdir + "</a> / "
    incdir = incdir + partdir + "/"

print cgi.escape(soundfileonly) + "</p><br clear='all'/>"

isblacklisted = 0
if os.path.exists(myconfig['savedir'] + "blacklists/" + playlist):
    blacklist = open (myconfig['savedir'] + "blacklists/" + playlist)
    for rule in blacklist.readlines():
        if re.match('.*' + rule[:-1] + '.*', soundfile):
            isblacklisted = 1
    blacklist.close()

escapedfile = urllib.quote(soundfile)

if not os.access(mediadir + soundfile, os.R_OK):
    print "<h1>Sorry, Oyster does not have the permission to read this file!</h1>"
    print "</body></html>"
    sys.exit()

print "<table width='100%'><tr>"
(mayVote, reason) = mCommon.may_vote(soundfile,None)
if oysterruns and mayVote:
    print "<td align='left'><span class='file'><a class='file' href='mHome.py?" + \
        "vote=" + escapedfile + "' >Diesen Song w&uuml;nschen</a> " + \
        "</span></td>"
elif oysterruns and not mayVote:
    print "<td><span class='file' " +\
          " style='font-style: italic;' '>" + reason + "</span></td>"
else:
    print "<td></td>"

regexfile = urllib.quote("^" + re.escape(soundfile) + "$")

tag = taginfo.get_tag(mediadir + soundfile)

timesplayed = 0
logmatcher = re.compile('\A[0-9]{4}[0-9]{2}[0-9]{2}\-[0-9]{2}[0-9]{2}[0-9]{2}\ ([^\ ]*)\ (.*)\Z')
log = open (myconfig['savedir'] + "logs/" + playlist)
for line in log.readlines():
    matcher = logmatcher.match(line[:-1])
    if matcher != None and matcher.group(2).find(soundfile) > -1 and matcher.group(1) == 'DONE':
        timesplayed = timesplayed + 1

log.close()

albumdir = os.path.dirname(mediadir + soundfile) + "/"
coverdata = mCommon.get_cover(albumdir, "100")

print "<table border='0'>"
if tag.has_key('title'):
    print "<tr><td class='fileinfo'><strong>Titel</strong></td><td>" + tag['title'] + "</td></tr>"

if tag.has_key('artist'):
    print "<tr><td class='fileinfo'><strong>K&uuml;nstler</strong></td><td>"
    print "<a href='mSearch.py?searchtype=normal&amp;playlist=current&amp;" + \
        "search=" + urllib.quote(tag['artist']) + "' title='Search for " + \
        "this artist'>" + tag['artist'] + "</a></td></tr>"

if coverdata != '':
    print "<tr><td class='fileinfo'><strong>Cover</strong></td><td>" + coverdata + "</td></tr>"

tagtuple = (
    ('Album', 'album'),
    ('Track Nummer', 'track'),
    ('Jahr', 'year'),
    ('Genre', 'genre'),
    ('Kommentar', 'comment'),
    ('Laufzeit', 'playtime')
)

for line in tagtuple:
    if tag.has_key(line[1]):
        print "<tr><td class='fileinfo'><strong>" + line[0] + "</strong></td>" + \
            "<td>" + tag[line[1]] + "</td></tr>"

print "</table>"

print "</body></html>"
