#!/usr/bin/python
# -*- coding: ISO-8859-1 -*
# oyster - a perl-based jukebox and web-frontend
#
# Copyright (C) 2004 Benjamin Hanzelmann <ben@nabcos.de>, Stephan Windmüller <windy@white-hawk.de>, Stefan Naujokat <git@ethric.de>
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

import config
import os
import os.path
import time

myconfig = config.get_config('oyster.conf')

def do_action (action, filename):

    filename = os.path.normpath(str(filename))
    filename = filename.replace('//','/')
    filename = filename.replace('../','')
    if filename == '..':
        filename = ''

    if os.path.isfile(myconfig['basedir'] + 'status'):
       statusfile = open(myconfig['basedir'] + 'status')
       status = statusfile.readline()[:-1]
       statusfile.close()
    else:
        status = ''

    mediadir = myconfig['mediadir'][:-1]

    if action != 'start':
        control = open(myconfig['basedir'] + 'control', 'w')
    
    if action == 'skip':
        control.write("NEXT\n")
        control.close()
        time.sleep(4)
    elif action == 'prev':
        control.write("PREV\n")
        control.close()
        time.sleep(4)
    elif action == 'start':
        os.system('python oyster.py &')
        waitmax = 100
        while waitmax > 0:
            if os.path.isfile(myconfig['basedir'] + 'info'):
                waitmax = 0
            else:
                time.sleep (1)
                waitmax = waitmax - 1
    elif action == 'stop':
        control.write("QUIT\n")
        control.close()
    elif action == 'pause':
        if (status == 'paused'):
            control.write("UNPAUSE\n'")
            status = 'playing'
        elif (status == 'playing'):
            control.write("PAUSE\n")
            status = 'paused'
        control.close()
    elif action == 'scoreup' and filename:
        control.write("SCORE + " + mediadir + filename + "\n")
        control.close()
    elif action == 'scoredown' and filename:
        control.write("SCORE - " + mediadir + filename + "\n")
        control.close()
    elif action == 'unvote' and filename:
        control.write("UNVOTE " + mediadir + filename + "\n")
        control.close()
    elif action == 'loadlist' and filename:
        control.write("LOAD " + filename + "\n")
        control.close()
    elif action == 'enqueue' and filename:
        filename = filename[1:]
        control.write("ENQUEUE " + myconfig['mediadir'] + filename + "\n")
        control.close()
    elif action == 'addnewlist' and filename:
        filename = os.path.basename(filename)
        newlist = open(myconfig['savedir'] + "lists/" + filename, 'w')
        newlist.close()
        newlist = open(myconfig['savedir'] + "blacklists/" + filename, 'w')
        newlist.close()
        newlist = open(myconfig['savedir'] + "logs/" + filename, 'w')
        newlist.close()
        newlist = open(myconfig['savedir'] + "scores/" + filename, 'w')
        newlist.close()
    elif action == 'delete' and filename:
        filename = os.path.basename(filename)
        os.unlink(myconfig['savedir'] + "blacklists/" + filename)
        os.unlink(myconfig['savedir'] + "lists/" + filename)
        os.unlink(myconfig['savedir'] + "logs/" + filename)
        os.unlink(myconfig['savedir'] + "scores/" + filename)
    elif action == 'favmode':
        control.write("FAVMODE\n")
        control.close()
    elif action == 'nofavmode':
        control.write("NOFAVMODE\n")
        control.close()

    return status

def do_vote (votefile):
    votefile = myconfig['mediadir'] + votefile[1:]
    control = open(myconfig['basedir'] + "control")
    control.write("VOTE " + votefile + "\n")
    control.close()
    time.sleep (1)

def do_votelist (votelist):
    votelist = myconfig['mediadir'] + votelist[1:]
    control = open(myconfig['basedir'] + "control")
    control.write("ENQLIST " + votelist + "\n")
    control.close()
    time.sleep (1)
