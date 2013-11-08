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

import cgi
import cgitb
import config
import fifocontrol
import os.path
import urllib
import re
import commands
cgitb.enable()

myconfig = config.get_config()
basedir = myconfig['basedir']
mediadir = myconfig['mediadir'][:-1]
form = cgi.FieldStorage()

try:
    if form['action'].value.count('favmode') > 0 and os.path.exists(myconfig['basedir'] + 'control'):
        fifocontrol.do_action(form['action'].value, '')
except KeyError:
    pass

try:
    cmd = ""
    volume = form['vol'].value
    if volume == 'down':
        fifocontrol.do_action("voldown", '')
    elif volume == 'up':
        fifocontrol.do_action("volup", '')
    elif int(volume) > 0:
        fifocontrol.do_action("volset " + volume, '')
except KeyError:
    pass

print "Content-Type: text/html; charset=" + myconfig['encoding'] + "\n"
print "<?xml version='1.0' encoding='" + myconfig['encoding'] + "' ?>"
print """
<!DOCTYPE html 
     PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
          "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
 <title>Oyster-GUI</title>
"""
print "<meta http-equiv='Content-Type' content='text/html; charset=" + myconfig['encoding'] + "' />"
print "<link rel='stylesheet' type='text/css' href='themes/" + myconfig['theme'] + "/layout.css' />"
print "</head>"
print "<body>"

print "<div><a href='control.py' style='position:absolute; top:2px; right:2px' title='Refresh'>"
print "<img src='themes/" + myconfig['theme'] + "/refresh.png' alt='Refresh'/></a></div>"



try:
    volfile = open(myconfig['basedir'] + 'volume')
    volume = volfile.readline()[:-1]
    volfile.close()
except IOError:
    volume = "unknown"
#volume = re.sub('\Apcm\ ','',volume)

# Is oyster in FAV-Mode?

try:
    favfile = open(myconfig['basedir'] + 'favmode')
    favmode = favfile.readline()[:-1]
    favfile.close()
except IOError:
    favmode = 'off'

print "<table width='80%' style='margin-left: auto; margin-right: auto;'><tr>";
print "<td align='center' style='margin: 0; padding: 0'><a href='oyster-gui.py?action=start' target='curplay' title='Start Oyster'>"
print "<img src='themes/" + myconfig['theme'] + "/play.png' alt='Start'/></a></td>"
print "<td align='center'><a href='oyster-gui.py?action=stop' target='curplay' title='Stop Oyster'>"
print "<img src='themes/" + myconfig['theme'] + "/stop.png' alt='Stop'/></a></td>"
 
if favmode == 'on':
	print "<td align='center'><a href='control.py?action=nofavmode' title='Deactivate FAV Mode'>"
	print "<img src='themes/" + myconfig['theme'] + "/favmodeon.png' alt='FAV on'/></a></td>"
else:
	print "<td align='center'><a href='control.py?action=favmode' title='Activate FAV Mode'>"
	print "<img src='themes/" + myconfig['theme'] + "/favmodeoff.png' alt='FAV off'/></a></td>"


print "<td rowspan='2' align='center' style='line-height:180%'><a href='control.py?vol=up'"
print "title='Volume up'><img src='themes/" + myconfig['theme'] + "/volup.png' alt='Volume Up'/></a><br/>"
print "<a href='control.py?vol=" + myconfig['midvolume'] + "' title='Set volume to " + myconfig['midvolume'] + "%'>Volume " + volume + "</a><br/>"
print "<a href='control.py?vol=down' title='Volume down'><img src='themes/" + myconfig['theme'] + "/voldown.png'"
print "alt='Volume Down'/></a></td>"
print "</tr><tr>"
print "<td align='center'><a href='oyster-gui.py?action=pause' target='curplay' title='Pause/Unpause'>"
print "<img src='themes/" + myconfig['theme'] + "/pause.png' alt='Pause'/></a></td>"
print "<td align='center'><a href='oyster-gui.py?action=prev' target='curplay' title='Previous song'>"
print "<img src='themes/" + myconfig['theme'] + "/prev.png' alt='Prev'/></a></td>"
print "<td align='center'><a href='oyster-gui.py?action=next' target='curplay' title='Next song'>"
print "<img src='themes/" + myconfig['theme'] + "/skip.png' alt='Skip'/></a></td>"
print "</tr></table>"
print "</body></html>"
