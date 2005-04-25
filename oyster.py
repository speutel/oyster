#!/usr/bin/python
# -*- coding: iso8859-1 -*-

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

import os, logging, logging.config
import oysterconfig

class Oyster:
    configfile = os.getcwd() + "/oyster.conf"
    config = {}

    scorelist = []
    scorepointer = 0
    scoresfile = ""
    scoresdir = ""
    scoressize = "100"

    savedir = ""
    basedir = ""
    listdir = ""
    mediadir = ""
    blacklistdir = ""
    logdir = ""

    votefile = ""
    votepercentage = 20

    playlist = "default"
    favmode = False

    def __init__(self):
        log.debug("start init")
        
        # get config and get values into "real" variables
        self.config = oysterconfig.getConfig(self.configfile)
       
        # paths never end with "/" 
        self.savedir = self.config["savedir"].rstrip("/")
        self.listdir = self.savedir + "/lists"
        self.scoresfile = self.savedir + "/scores/" + self.playlist
        self.scoresdir = self.savedir + "/scores"
        self.blacklistdir = self.savedir + "/blacklists"
        self.logdir = self.savedir + "/logs"

        self.mediadir = self.config["mediadir"].rstrip("/")

        self.basedir = self.config["basedir"].rstrip("/")
        self.votefile = self.basedir + "/votes"
        self.votepercentage = self.config["voteplay"].rstrip("/")
        self.scoressize = int(self.config["maxscored"])

        # setup basedir
        if not os.access(self.basedir, os.F_OK):
            log.debug("setup basedir")
            os.makedirs(self.basedir)
        else: 
            # already exists. check for another running oyster and unpause.
            # no oyster -> remove dir
            log.debug("basedir exists")
            if os.access(self.basedir + "/pid", os.R_OK):
                pidfile = open(self.basedir + "/pid", 'r')
                pid = pidfile.readline()
                # check pid - is this pid an instance of oyster?
                pspipe = popen("ps -o command= -p " + pid, 'r')
                log.debug("check pid for oyster")
                if (pspipe.readline().find("oyster") != -1):
                    log.debug("unpausing running oyster")
                    controlfile = open(self.basedir + "/control", 'w')
                    controlfile.writeline("UNPAUSE\n")
                    controlfile.close()
                    sys.exit()
            # no pid file or pid is no oyster (-> sys.exit() is not triggered, no "else:")
            log.debug("removing old basedir")
            for root, dirs, files in os.walk(self.basedir, topdown=False):
                for name in files:
                    os.remove(os.path.join(root, name))
                for name in dirs:
                    os.rmdir(os.path.join(root, name))
            os.rmdir(self.basedir)
            os.makedirs(self.basedir)

        # setup savedir
        log.debug("setup savedir")
        if not os.access(self.savedir, os.F_OK):
            os.makedirs(self.savedir)
        if not os.access(self.listdir, os.F_OK):
            os.makedirs(self.listdir)
        if not os.access(self.blacklistdir, os.F_OK):
            os.makedirs(self.blacklistdir)
        if not os.access(self.scoresdir, os.F_OK):
            os.makedirs(self.scoresdir)    
        if not os.access(self.logdir, os.F_OK):
            os.makedirs(self.logdir)
        
        # write current pid
        log.debug("writing pid")
        pidfile = open(self.basedir + "/pid", 'w')
        pidfile.write(str(os.getpid()) + "\n")
        pidfile.close()
        
        # write name of current playlist (in init -> default) 
        log.debug("writing playlist")
        plfile = open(self.basedir + "/playlist", 'w')
        plfile.write("default\n")
        plfile.close()

        # read old default-playlist (list of all files in mediadir)
        # (one song is played from there while we build the new list) 
        log.debug("reading old default list")
        if os.access(self.listdir + "/default", os.R_OK):
            deflist = open(self.listdir + "/default", 'r')
            for line in deflist.readlines():
                self.filelist.append(line.rstrip())

        # read scores for playlist 
        self.update_scores()

        # initialize random
        # FIXME  

        # make fifos
        log.debug("make fifos")
        os.mkfifo(self.basedir + "/control")
        # FIXME do we really need kidplay? 
        os.mkfifo(self.basedir + "/kidplay")

        # favmod is off at start
        favfile = open(self.basedir + "/favmode", 'w')
        favfile.write("off\n")
        favfile.close()

        log.debug("end init")

    def update_scores(self):
        log.debug("updating scores")
        if os.access(self.scoresfile, os.R_OK):
            sfile = open(self.scoresfile, 'r')
            self.scorespointer = sfile.readline().rstrip()
            for line in sfile.readlines():
                scores.append(line.rstrip())
            sfile.close()
        # FIXME cut off entries after scoressize has changed!


if __name__ == '__main__':
    logging.config.fileConfig("oysterlog.conf")
    log = logging.getLogger("oyster")
    oyster = Oyster()
