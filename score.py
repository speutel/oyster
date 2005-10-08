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
import fifocontrol
import cgitb
import urllib
import common
import os.path
cgitb.enable()

myconfig = config.get_config()
basedir = myconfig['basedir']
savedir = myconfig['savedir']
mediadir = myconfig['mediadir'][:-1]
form = cgi.FieldStorage()
playlist = config.get_playlist()

# Is oyster currently running?

if os.path.exists(myconfig['basedir']):
    oysterruns = 1
else:
    oysterruns = 0
    
if form.has_key('action'):
    fifocontrol.do_action(form['action'].value, form['file'].value)

common.navigation_header()

score = {}
maxscore = 1

if os.path.exists(myconfig['savedir'] + "scores/" + playlist):
    scorefile = open (myconfig['savedir'] + "scores/" + playlist)
    scorefile.readline() # skip initial number
    for line in scorefile.readlines():
        line = line[:-1]
        if score.has_key(line):
            score[line] = score[line] + 1
            if maxscore < score[line]:
                maxscore = score[line]
        else:
            score[line] = 1
    scorefile.close()

# Get Tags of all files

display = {}

for key in score.keys():
    display[key] = taginfo.get_tag_light(key)

# Print all files

print "<table id='scoretable'>"
print "<tr><th>Song</th><th width='75'>Score</th></tr>"

cssclass = 'file2'

while maxscore > 0:

    printed = 0

    files = []

    for key in score.keys():
        if score[key] == maxscore:
            files.append(key)

    def filesort(a, b):
        return cmp(display[a], display[b])

    files.sort(filesort)

    for curfile in files:

        printed = 1

        escapedfile = curfile.replace(mediadir, '', 1)
        escapedfile = urllib.quote(escapedfile)

        # cssclass changes to give each other file
        # another color

        if cssclass == 'file':
            cssclass = 'file2'
        else:
            cssclass = 'file'

        if oysterruns:
            print "<tr><td><a href='oyster-gui.py?action=enqueue&amp;file=" + escapedfile + "' target='curplay' " + \
                "title='Enqueue'><img src='themes/" + myconfig['theme'] + "/enqueue" + cssclass + ".png'" + \
                "alt='Enqueue'/></a> <a class='" + cssclass + "' href='fileinfo.py?file=" + \
                escapedfile + "'>" + display[curfile] + "</a></td>"
            print "<td align='center'><a class= '" + cssclass + "' href='score.py?action=scoredown&amp;file=" + escapedfile + "' " + \
                "title='Score down'><img src='themes/" + myconfig['theme'] + "/scoredown" + cssclass + ".png' " + \
                "alt='-'/></a> <span class='" + cssclass + "'><strong>" + str(score[curfile]) + "</strong></span>"
            print " <a class='" + cssclass + "' href='score.py?action=scoreup&amp;file=" + escapedfile + "' " + \
                "title='Score up'><img src='themes/" + myconfig['theme'] + "/scoreup" + cssclass + ".png' alt='+'/></a></td></tr>"
        else:
            print "<tr><td><a class='" + cssclass + "' href='fileinfo.py?file=" + \
                escapedfile + "'>" + display[curfile] + "</a></td>"
            print "<td align='center'><span class='" + cssclass + "'><strong>" + str(score[curfile]) + "</strong></span></td></tr>"
            

    maxscore = maxscore - 1

    if printed:
        print "<tr><td colspan='2'>&nbsp;</td></tr>"

print "</table>"
print "</body></html>"
