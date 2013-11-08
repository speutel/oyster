#!/usr/bin/python
# -*- coding: UTF-8 -*-

# oyster - a python-based jukebox and web-frontend
#
# Copyright (C) 2004 Benjamin Hanzelmann <ben@nabcos.de>,
# Stephan Windmüller <windy@white-hawk.de>, Stefan Naujokat <git@ethric.de>
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
fifocontrol provides functions to use the oyster-FIFO
"""

__revision__ = 1

import config
import os
import os.path
import time

myconfig = config.get_config()

def do_action (action, filename):
    """
    Parses the action parameter and writes the
    needed commands into the FIFO
    """


    filename = os.path.normpath(str(filename))
    filename = filename.replace('//','/')
    filename = filename.replace('../','')
    if filename == '..':
        filename = ''

    mediadir = myconfig['mediadir'][:-1]

    status = ''

    if os.path.isfile(myconfig['basedir'] + 'status'):
        statusfile = open(myconfig['basedir'] + 'status')
        status = statusfile.readline()
        statusfile.close()
    
    if action != 'start' and action != 'addnewlist':
        control = open(myconfig['basedir'] + 'control', 'w')

    # Someone wants to start a paused oyster
    if action == 'start' and status == 'paused':
        control = open(myconfig['basedir'] + 'control', 'w')
    
    if action[:12] == 'changerandom':
        nextskip = int(action[12:])
        filenum = -1
        
        allnextfiles = open(myconfig['basedir'] + 'nextfile', 'r')
        nextfiles = allnextfiles.readlines()
        allnextfiles.close()
        
        while nextskip > -1:
            if nextfiles[nextskip].rstrip() == mediadir + filename:
                filenum = nextskip
                break
            else:
                nextskip -= 1
        
        if filenum > -1:
            control.write("CHANGERANDOM " + str(filenum) + "\n")
        control.close()
        time.sleep(1)
    elif action[:9] == 'delrandom':
        nextskip = int(action[9:])
        filenum = -1
        
        allnextfiles = open(myconfig['basedir'] + 'nextfile', 'r')
        nextfiles = allnextfiles.readlines()
        allnextfiles.close()
        
        while nextskip > -1:
            if nextfiles[nextskip].rstrip() == mediadir + filename:
                filenum = nextskip
                break
            else:
                nextskip -= 1
        
        if filenum > -1:
            control.write("DELRANDOM " + str(filenum) + "\n")
        control.close()
        time.sleep(1)
    elif action == 'next':
        control.write("NEXT\n")
        control.close()
        time.sleep(4)
    elif action == 'prev':
        control.write("PREV\n")
        control.close()
        time.sleep(4)
    elif action == 'start':
        if status == 'paused':
            control.write("PAUSE\n")
            control.close()
            time.sleep(4)
        else:
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
        control.write("PAUSE\n")
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
        if not os.path.exists(myconfig['savedir'] + "lists/" + filename):
            newlist = open(myconfig['savedir'] + "lists/" + filename, 'w')
            newlist.close()
            newlist = open(myconfig['savedir'] + "logs/" + filename, 'w')
            newlist.close()
    elif action == 'delete' and filename:
        filename = os.path.basename(filename)
        for dirname in ['blacklists/', 'lists/', 'logs/', 'scores/']:
            if os.path.exists(myconfig['savedir'] + dirname + filename):
                os.unlink(myconfig['savedir'] + dirname + filename)
    elif action == 'favmode':
        control.write("FAVMODE\n")
        control.close()
    elif action == 'nofavmode':
        control.write("NOFAVMODE\n")
        control.close()
    elif action.startswith('vol'):
        if action == 'voldown':
            control.write("VOLDOWN\n")
        elif action == 'volup':
            control.write("VOLUP\n")
        elif action.startswith('volset'):
            control.write("VOLSET " + action[7:] + "\n")
        control.close()

def do_vote (votefile):
    """
    Votes a single file
    """
    votefile = myconfig['mediadir'] + votefile[1:]
    control = open(myconfig['basedir'] + "control",'w')
    control.write("VOTE " + votefile + "\n")
    control.close()
    time.sleep (1)

def do_votelist (votelist):
    """
    Enqueues a complete playlist in m3u-format
    """
    votelist = myconfig['mediadir'] + votelist[1:]
    control = open(myconfig['basedir'] + "control", 'w')
    control.write("ENQLIST " + votelist + "\n")
    control.close()
    time.sleep (1)
