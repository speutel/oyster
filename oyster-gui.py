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
import commands
import re
cgitb.enable()

myconfig = config.get_config('oyster.conf')
basedir = myconfig['basedir']
mediadir = myconfig['mediadir'][:-1]
form = cgi.FieldStorage()

if form.has_key('file'):
    filename = form['file'].value
else:
    filename = ''

if form.has_key('action'):
    action = form['action'].value
    fifocontrol.do_action(action, filename)
else:
    action = ''

if os.path.isfile(myconfig['basedir'] + 'status'):
    statusfile = open(myconfig['basedir'] + 'status')
    status = statusfile.readline()
    statusfile.close()
else:
    status = ''
    
if form.has_key('vote'):
    fifocontrol.do_vote(form['vote'].value)

if form.has_key('votelist'):
    fifocontrol.do_votelist(form['votelist'].value)

print "Content-Type: text/html"
print """
<?xml version="1.0" encoding="iso-8859-1"?>
<!DOCTYPE html 
         PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
         "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
 <title>Oyster-GUI</title>
 <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1"/>
 <meta http-equiv="refresh" content="30; URL=oyster-gui.py"/>
 <link rel="stylesheet" type="text/css" href="themes/default/layout.css"/>
</head>
<body>
"""

print "<div><img src='themes/" + myconfig['theme'] + "/logo.png' alt='Oyster' width='300' style='margin-bottom:10px'/></div>"
print "<div style='position:absolute; top:2px; right:2px'><a href='oyster-gui.py' title='Refresh'>"
print "<img src='themes/" + myconfig['theme'] + "/refresh.png' alt='Refresh'/></a></div>"

if not os.path.isdir(basedir) or action == 'stop':
    print '<p>Oyster has not been started yet!</p>'
    print "<p><a href='oyster-gui.py?action=start'>Start</a>"
    print "</body></html>"
    sys.exit()

if not os.path.isfile(basedir + 'info'):
    print '<p>Oyster has not created needed files in ' + basedir + '</p>'
    print "</body></html>"
    sys.exit()

infofile = open(basedir + 'info')
info = infofile.readline()[:-1]
infofile.close()

nextarray = []
if os.path.exists(basedir + 'nextfile'):
    nextfile = open(basedir + 'nextfile')
    for line in nextfile.readlines():
        nextarray.append(line[:-1])
    nextfile.close()

tag = taginfo.get_tag(info)

# Get playreason from last 10 lines of logfile

playlist = config.get_playlist()
lastlines = commands.getoutput('tail -n 10 "logs/' + playlist + '"').split("\n")
lastlines.reverse()
for line in lastlines:
    matcher = re.match('\A[^\ ]*\ ([^\ ]*)\ (.*)\Z', line)
    if matcher != None:
        playreason = matcher.group(1)
        playedfile = matcher.group(2)
        if playreason in ['PLAYLIST', 'SCORED', 'ENQUEUED', 'VOTED']:
            break

# Possible wrong playlist - check filename

if playedfile != info:
    playreason = ''

if playreason == 'PLAYLIST':
    playreason = ' (random)'
elif playreason == 'SCORED':
    playreason = ' (scored)'
elif playreason == 'ENQUEUED':
    playreason = ' (enqueued)'
elif playreason == 'VOTED':
    playreason = ' (voted)'
else:
    playreason = ''

info = re.sub('\A' + re.escape(myconfig['mediadir']), '', info)
info = urllib.quote("/" + info)

# Get current status of favmode

favfile = open(basedir + 'favmode')
favmode = favfile.readline()[:-1]
favfile.close()

# If FAVMODE is on, every "scored" is substituded to "favorites only", but
# enqueued and voted remain. (random should not be possible ;))
if favmode == 'on' and not (playreason == ' (voted)' or playreason == ' (enqueued)'):
    playreason = ' (favorites only)'

if status == 'paused':
    statusstr = " <a href='oyster-gui.py?action=pause'>Paused</a>"
else:
    statusstr = ''

print "<table width='100%' border='0'>"
print "<tr><td colspan='2'><strong>Now playing" + playreason + ":</strong></td>"
print "<td align='center' style='width:75px'><strong>Score</strong></td></tr>"
print "<tr><td>"
print "<strong><a class='file' href='fileinfo.py?file=" + info + "' target='browse' title='View details'>" + tag['display'] + "</a>"
print statusstr + "</strong></td>"
print "<td></td>"
print "<td align='center' style='padding-left:10px; padding-right:10px'>"
print "<a href='oyster-gui.py?action=scoredown&amp;file=" + info + "' title='Score down'>"
print "<img src='themes/" + myconfig['theme'] + "/scoredownfile.png' border='0' alt='-'/></a> "
print "<strong>" + str(tag['score']) + "</strong> "
print "<a href='oyster-gui.py?action=scoreup&amp;file=" + info + "' title='Score up'>"
print "<img src='themes/" + myconfig['theme'] + "/scoreupfile.png' border='0' alt='+'/>"
print "</a></td></tr>"

print "<tr><td colspan='3'>&nbsp;</td></tr>"

if os.path.exists(basedir + 'votes') and os.path.getsize(basedir + 'votes') > 0:
    maxvotes = 0
    votes = {}
    votelist = []
    
    votefile = open(basedir + 'votes')
    for vote in votefile.readlines():
        matcher = re.match('\A(.*),([0-9]*)', vote)
        if matcher != None:
            title = matcher.group(1)
            numvotes = int(matcher.group(2))
            votes[title] = numvotes
            votelist.append(title)
            if numvotes > maxvotes:
                maxvotes = numvotes
    votefile.close()
            
    print "<tr><td width='70%' align='left'><strong>Voted File</strong></td><td align='center'><strong>Votes</strong></td><td></td></tr>"

    while maxvotes > 0:
        for filename in votelist:
            if votes[filename] == maxvotes:
                display = taginfo.get_tag_light(filename)
                title = re.sub('\A' + mediadir, '', filename)
                escapedtitle = urllib.quote(title)
                print "<tr><td>"
                print "<a class='file' href='fileinfo.py?file=" + escapedtitle + "' target='browse'>" + display + "</a>"
                print "</td><td align='center'>" + str(votes[filename]) + "</td>"
                print "<td align='center'><a href='oyster-gui.py?action=unvote&amp;file=" + escapedtitle + "'>Unvote</a>"
                print "</td></tr>"
        maxvotes -= 1

    print "<tr><td colspan='3'>&nbsp;</td></tr>"


print "<tr><td colspan='2'><strong>Next random:</strong></td>"
print "<td></td></tr>"
i = 0
for nextinfo in nextarray:
    nexttag = taginfo.get_tag(nextinfo)
    nextinfo = re.sub('\A' + re.escape(myconfig['mediadir']), '', nextinfo)
    nextinfo = urllib.quote("/" + nextinfo)
    print "<tr><td>"
    print "<strong><a class='file' href='fileinfo.py?file=" + nextinfo + "' target='browse' title='View details'>"
    print nexttag['display'] + "</a></strong></td>"
    print "<td></td>"
    print "<td align='center' style='padding-left:10px; padding-right:10px'>"
    print "<a href='oyster-gui.py?action=skip&file=" + nextinfo + "'>Change</a>"
    print "</td></tr>"
    i = i +1
print "</table>"


print "</body></html>"
