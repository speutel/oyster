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

"Checks the scorefile for non-existing files"

__revision__ = 1

import cgi
import config
import cgitb
import common
import os.path
import fifocontrol
import sys
cgitb.enable()

common.navigation_header()

myconfig = config.get_config()
mediadir = myconfig['mediadir'][:-1]
form = cgi.FieldStorage()
playlist = config.get_playlist()

if not os.path.exists(myconfig['basedir']):
    print "<h1>Please <a href='oyster-gui.py?action=start' target='curplay'>" \
        + "start oyster</a> before clearing the scorefile!</h1>"
    sys.exit()

# Load scorefile into permanent array

scorefile = open (myconfig['savedir'] + "scores/" + playlist)
scorefile.readline()
scores = scorefile.readlines()
scorefile.close()

if not form.has_key('action'):

    alreadyshown = []
    deletelist = []
    for line in scores:
        if not os.path.exists(line[:-1]) and line not in alreadyshown:
            deletelist.append(line[:-1])
            alreadyshown.append(line)

    if deletelist != []:
        print "<h1>The following files will be removed from the scorefile:</h1>"
        for filename in deletelist:
            print filename.replace(mediadir, '', 1) + "<br>"
        print "<br><a href='clearscores.py?action=delete'>" + \
            "Delete these entries</a>"
    else:
        print "<h1>There are no non-existing files in the scorefile.</h1>"

elif form['action'].value == 'delete':

    counter = 0
    for line in scores:
        if not os.path.exists(line[:-1]):
            fifocontrol.do_action('scoredown',line.replace(mediadir,'',1)[:-1])
            counter += 1

    print "<h1>" + str(counter) + " entries deleted.</h1>"
    
print "</body></html>"
