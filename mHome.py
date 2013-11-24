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

import cgi
import cgitb
import sys
import os.path
import urllib
import commands
import re

import config
import taginfo
import fifocontrol
import mCommon

_ = mCommon.get_prefered_language()


def check_oyster_started():
    if not os.path.exists(myconfig['savedir'] + 'blacklists') or not os.path.exists(myconfig['savedir'] + 'lists') \
            or not os.path.exists(myconfig['savedir'] + 'logs') or not os.path.exists(myconfig['savedir'] + 'scores'):
        print "<h1>New Oyster install?</h1>"
        print "<p>It seems that this is the first time you started Oyster.<br>"
        print "You might want to edit " + \
              "the configuration.</p>"
        print "<p>After that you should check your " + \
              "configuration for common errors such as wrong permissions.</p>"
        print "<p>If all seems correct, you are able to " + \
              "start Oyster for the " + \
              "first time.</p>"
        print "</body></html>"
        sys.exit()
    if not os.path.isdir(basedir) or action == 'stop':
        print '<p>Oyster has not been started yet!</p>'
        print "<p><a href='mHome.py?action=start'>Start</a></p>"
        print "</body></html>"
        sys.exit()
    if not os.path.isfile(basedir + 'info'):
        print '<p>Oyster has not created needed files in ' + basedir + '</p>'
        print "</body></html>"
        sys.exit()


def display_votes():
    global maxvotes, votes, votelist, votefile, vote, matcher, title, numvotes, filename, display, escapedtitle
    if os.path.exists(basedir + 'votes') and os.path.getsize(basedir + 'votes') > 0:
        maxvotes = 0
        votes = {}
        votelist = []

        votefile = open(basedir + 'votes')
        for vote in votefile.readlines():
            matcher = re.match('\A(.*),([0-9]*)', vote)
            if matcher is not None:
                title = matcher.group(1)
                numvotes = int(matcher.group(2))
                votes[title] = numvotes
                votelist.append(title)
                if numvotes > maxvotes:
                    maxvotes = numvotes
        votefile.close()

        print "<tr><td width='70%' align='left'><strong>" + _('Voted') + "</strong></td><td></td></tr>"

        while maxvotes > 0:
            for filename in votelist:
                if votes[filename] == maxvotes:
                    display = taginfo.get_tag_light(filename)
                    title = re.sub('\A' + mediadir, '', filename)
                    escapedtitle = urllib.quote(title)
                    print "<tr><td>"
                    print "<a class='file' href='mInfo.py?file=" + escapedtitle + "' >" + display + "</a>"
                    print "</td>"
                    print "<td>"
                    print "<a href='mHome.py?action=unvote&amp;file=" + \
                          escapedtitle + "' title='" + _('Unvote') + "'>"
                    print "<img src='themes/" + myconfig['theme'] + "/delrandom.png' alt='Delete'/></a>"
                    print "</td></tr>"
            maxvotes -= 1

        print "<tr><td colspan='2'>&nbsp;</td></tr>"


def display_next_random():
    global i, nextinfo, nexttag
    i = 0

    print "<tr><td colspan='2'><strong>" + _('Next Random') + ":</strong></td></tr>"
    for nextinfo in nextarray:
        nexttag = taginfo.get_tag(nextinfo)
        nextinfo = re.sub('\A' + re.escape(myconfig['mediadir']), '', nextinfo)
        nextinfo = urllib.quote("/" + nextinfo)
        print "<tr>"

        print "<td><strong><a class='file' href='mInfo.py?file=" + nextinfo + "' title='" + _('View details') + "'>"
        print nexttag['display'] + "</a></strong></td>"

        print "<td style='min-width:40px'><a href='mHome.py?action=changerandom" + str(i) + \
              "&amp;file=" + nextinfo + "' title='" + _('Replace_With_Random') + "'>"
        print "<img src='themes/" + myconfig['theme'] + "/changerandom.png' alt='Change'/></a>"
        print "<a href='mHome.py?action=delrandom" + str(i) + "&amp;file=" + \
              nextinfo + "' title='" + _('Delete_Song') + "'>"
        print "<img src='themes/" + myconfig['theme'] + "/delrandom.png' alt='Delete'/></a></td>"

        print "</tr>"
        i += 1

    print "<tr><td colspan='2'>&nbsp;</td></tr>"


def display_play_controls():

    def __print_action_link(action, title, image, altTag):
        print "<a href='mHome.py?action=" + action + "' title='" + title + "'>"
        print "<img src='themes/" + myconfig['theme'] + "/" + image + "' alt='" + altTag + "'/></a>"
        pass

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

    print "<tr><td>"
    __print_action_link("start", _("Start Oyster"), "play.png", _("Start"))
    __print_action_link("pause", _("Pause/Unpause"), "pause.png", _("Pause"))
    __print_action_link("stop", _("Stop Oyster"), "stop.png", _("Stop"))
    if favmode == 'on':
        __print_action_link("nofavmode", _("Deactivate FAV Mode"), "favmodeon.png", "FAV on")
    else:
        __print_action_link("favmode", _("Activate FAV Mode"), "favmodeoff.png", "FAV off")
    __print_action_link("prev", _("Previous Song"), "prev.png", _("Previous Song"))
    __print_action_link("next", _("Next Song"), "skip.png", _("Skip Song"))
    print "<a href='extras.py' title='Extras'>"
    print "<img src='themes/" + myconfig['theme'] + "/extras.png' alt='Extras'/></a>"
    print "</td></tr>"

    print "<tr><td>"
    __print_action_link("voldown", "Lower Volume", "voldown.png", _("Lower Volume"))
    print "<a href='mHome.py?vol=" + myconfig['midvolume'] + "' title='Set volume to " + myconfig[
        'midvolume'] + "%'>Volume " + volume + "</a>"
    __print_action_link("volup", "Increase Volume", "volup.png", _("Increase Volume"))
    print "</td></tr></table>"

cgitb.enable()

myconfig = config.get_config()
basedir = myconfig['basedir']
mediadir = myconfig['mediadir'][:-1]
form = cgi.FieldStorage()

if 'file' in form:
    filename = form['file'].value
else:
    filename = ''

if 'action' in form:
    action = form['action'].value
    if action == 'start' or os.path.exists(basedir):
        fifocontrol.do_action(action, filename)
else:
    action = ''

if 'vol' in form:
    volumeLevel = form['vol'].value
    fifocontrol.do_action("volset " + myconfig['midvolume'], filename)

if os.path.isfile(myconfig['basedir'] + 'status'):
    statusfile = open(myconfig['basedir'] + 'status')
    status = statusfile.readline()
    statusfile.close()
else:
    status = ''

notVotedReason = None
if 'vote' in form:
    (mayVote, notVotedReason) = mCommon.may_vote(form['vote'].value, None)
    if mayVote:
        fifocontrol.do_vote(form['vote'].value)

if 'votelist' in form:
    fifocontrol.do_votelist(form['votelist'].value)

mCommon.navigation_header(title="&Uuml;bersicht", refreshPage="mHome.py")

check_oyster_started()

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
playedfile = ''
playreason = ''
lastlines = commands.getoutput('tail -n 10 "logs/' + playlist + '"').split("\n")
lastlines.reverse()
for line in lastlines:
    matcher = re.match('\A[^ ]* ([^ ]*) (.*)\Z', line)
    if matcher is not None:
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
    statusstr = " (angehalten)"
else:
    statusstr = ''

if notVotedReason is not None:
    print "<p style='color:red'>Song kann nicht gew&uuml;nscht werden. Grund: " + notVotedReason + ".</p>"

print "<table border='0'>"
print "<tr><td colspan='2'><strong>" + _('Currently Playing') + ":</strong></td>"
print "</tr>"
print "<tr><td>"
print "<strong><a class='file' href='mInfo.py?file=" + info + "' title='View details'>" + tag['display'] + "</a>"
print statusstr + "</strong></td>"
print "<td></td>"
print "</td></tr>"

print "<tr><td colspan='2'>&nbsp;</td></tr>"

display_votes()
display_next_random()
display_play_controls()

print "</table>"

print "</body></html>"


