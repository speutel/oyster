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

import os, sys, logging, logging.config, random, thread, threading, time
import signal
import oysterconfig

class Oyster:
    configfile = os.getcwd() + "/oyster.conf"
    config = {}
    filelist = []

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
    controlfile = ""
    control = None

    filetypes = {}
    filetoplay = ""
    nextfiletoplay = ""
    threadid = None

    playerid = 0
    playthread = None
    doExit = False

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
        self.controlfile = self.basedir + "/control"

        for t in self.config["filetypes"].split(","):
            self.filetypes[t] = self.config[t]

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
                pspipe = os.popen("ps -o command= -p " + pid, 'r')
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
        random.seed()

        # make fifos
        log.debug("make fifos")
        os.mkfifo(self.basedir + "/control")
        # FIXME do we really need kidplay? 
        os.mkfifo(self.basedir + "/kidplay")

        # favmod is off at start
        favfile = open(self.basedir + "/favmode", 'w')
        favfile.write("off\n")
        favfile.close()
        
        if len(self.filelist) != 0:
            # fill files to play 
            self.choose_nextfile()
            self.choose_nextfile()

        # FIXME play file 
        
        self.build_playlist(self.mediadir)

        self.control = open(self.controlfile, 'r+')

        log.debug("end init")

    def update_scores(self):
        log.debug("updating scores")
        if os.access(self.scoresfile, os.R_OK):
            sfile = open(self.scoresfile, 'r')
            self.scorespointer = sfile.readline().rstrip()
            for line in sfile.readlines():
                self.scorelist.append(line.rstrip())
            sfile.close()
        # FIXME cut off entries after scoressize has changed!
    
    def choose_file(self):
        log.debug("choose file from list")
        if len(self.scorelist) != 0:
            # test if we play from scores or normal playlist 
            if random.randint(0, 100) < self.votepercentage:
                return random.choice(self.scorelist)
        return random.choice(self.filelist)
        
    def choose_nextfile(self):
        if self.filetoplay == "":
            log.debug("choose normal file to play (only happens directly after oyster start)")
            self.filetoplay = self.choose_file()
        else:
            log.debug("choose next file to play")
            self.nextfiletoplay = self.choose_file()

    def play_file(self):
        log.debug("playing file")

    def build_playlist(self, dir):
        log.debug("building playlist")
        for root, dirs, files in os.walk(self.mediadir, topdown=False):
            for name in files:
                if name[name.rfind(".")+1:] in self.filetypes.keys():
                    self.filelist.append(os.path.join(root, name))
        lfile = open(self.listdir + "/" + self.playlist, 'w')
        for line in self.filelist:
            lfile.write(line + "\n")
        lfile.close()
        log.debug("done writing list")

    def exit(self):
        log.debug("exiting oyster")

        self.doExit = True
        
        for root, dirs, files in os.walk(self.basedir, topdown=False):
            for name in files:
                os.remove(os.path.join(root, name))
            for name in dirs:
                os.rmdir(os.path.join(root, name))
        os.rmdir(self.basedir)

        # save scores
        sfile = open(self.scoresfile, 'w')
        sfile.write(str(self.scorepointer) + "\n")
        sfile.writelines(self.scorelist)
        sfile.close()

        # stop playthread 
        # FIXME signal 9??? 
        if oyster.playerid != 0:
            print oyster.playerid
            os.kill(oyster.playerid, 9)
        sys.exit()

    def play(self, f, realoyster):
        # suffixpos = f.rfind(".")
        # player = oyster.filetypes[f[suffixpos+1:]]
        # oyster.playerid = os.spawnl(os.P_NOWAIT, player, player, f)
        # os.waitpid(oyster.playerid, 0)
        # oyster.done()

        # self.playthread = PlayThread()
        # self.playthread.playfile = f
        # self.playthread.oyster = self
        # self.playthread.setDaemon(True)
        # self.playthread.start()
        suffixpos = f.rfind(".")
        player = self.filetypes[f[suffixpos+1:]]
        self.playerid = os.spawnl(os.P_NOWAIT, player, player, f)
        os.waitpid(self.playerid, 0)
        self.done()

    def done(self):
        if not self.doExit:
            self.filetoplay = self.nextfiletoplay
            self.choose_nextfile()
            self.play(self.filetoplay, self)

    def read_control(self):
        command = self.control.readline().rstrip()
        if command == "QUIT":
            self.exit()
        if command == "NEXT":
            self.next()
    
    def next(self):
        # FIXME was anderes als signal 9? 
        print self.playerid
        if self.playerid != 0:
            os.kill(self.playerid, signal.SIGQUIT)

class ControlThread(threading.Thread):
    oyster = None
    controlfile = None
    def startController(self, o, cfile):
        self.oyster = o
        self.controlfile = cfile
        self.start()
    def run(self):
        while 1:
            self.readControl()
    def readControl(self):
        command = self.controlfile.readline().rstrip()
        if command == "QUIT":
            oyster.exit()
        if command == "NEXT":
            oyster.next()                
        if command == "bla":
            print "Es lebt!"
        

if __name__ == '__main__':
    logging.config.fileConfig("oysterlog.conf")
    log = logging.getLogger("oyster")
    oyster = Oyster()
    print oyster.filetoplay
    print oyster.nextfiletoplay
    ct = ControlThread()
    ct.startController(oyster, oyster.control)
    oyster.play(oyster.filetoplay, oyster)
