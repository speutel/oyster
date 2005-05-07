#!/usr/local/bin/python
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

import os
import sys
import logging
import logging.config
import random
import threading
import time
import signal, re
import oysterconfig
import datetime

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
    votelist = []

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
    paused = False
    history = []
    mode = "vote"
    doNotSwitch = False
    playreason = ""
    nextreason = ""

    playlog = None

    def __init__(self):
        log.debug("start init")


        self.initConfig()

        # "needed" for __test_blacklist - stop recursing after 200 hits from the blacklist
        sys.setrecursionlimit(200)
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
        
        outfile = os.open("/dev/null", os.O_RDWR|os.O_CREAT|os.O_TRUNC)
        errfile = os.open("/dev/null", os.O_RDWR|os.O_CREAT|os.O_TRUNC)
        os.dup2(outfile, 1)
        os.dup2(errfile, 2)

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
        self.__write_playlist_status()
        log.debug("writing playlist")
        plfile = open(self.basedir + "/playlist", 'w')
        plfile.write("default\n")
        plfile.close()

        # read old default-playlist (list of all files in mediadir)
        # (one song is played from there while we build the new list) 
        log.debug("reading old default list")
        self.loadPlaylist("default")

        # read scores for playlist 
        self.__update_scores()

        # initialize random
        random.seed()

        # make fifos
        log.debug("make fifos")
        os.mkfifo(self.basedir + "/control")

        # favmod is off at start
        favfile = open(self.basedir + "/favmode", 'w')
        favfile.write("off\n")
        favfile.close()
        
        self.control = open(self.controlfile, 'r+')
        ct = ControlThread()
        ct.setDaemon(True)
        ct.startController(self, self.control)

        plhelper = PlaylistBuilder()
        plhelper.buildPlaylist(self)
        
        while len(self.filelist) == 0:
            pass


        # fill files to play 
        self.chooseFile()

        self.unpause()

        log.debug("end init")

    def __write_playlist_status(self):
        log.debug("writing playlist")
        plfile = open(self.basedir + "/playlist", 'w')
        plfile.write(self.playlist + "\n")
        plfile.close()

    def __update_scores(self):
        log.debug("updating scores")
        if os.access(self.scoresfile, os.R_OK):
            sfile = open(self.scoresfile, 'r')
            self.scorepointer = int(sfile.readline().rstrip())
            self.scorelist = []
            for line in sfile.readlines():
                self.scorelist.append(line.rstrip())
            sfile.close()
        else:
            self.scorespointer = 0
            self.scorelist = []
        # FIXME cut off entries after scoressize has changed!

    def __write_scores(self):
        # save scores
        sfile = open(self.scoresfile, 'w')
        sfile.write(str(self.scorepointer) + "\n")
        for line in self.scorelist:
            sfile.write(line + "\n")	
        sfile.close()

    def __write_history(self):
        hfile = open(self.basedir + "/history", 'w')
        for l in self.history:
            hfile.write(l + "\n")
        hfile.close()
    
    def __test_blacklist(self, name):
        if os.access(self.blacklistdir + "/" + self.playlist, os.R_OK):
            bfile = open(self.blacklistdir + "/" + self.playlist, 'r')
            for line in bfile.readlines():
                if re.compile(re.escape(line.rstrip())).search(name) != None:
                    return True
        return False

    def __choose_file(self):
        log.debug("choose file from list")
        if len(self.scorelist) != 0:
            # test if we play from scores or normal playlist 
            #randi = random.randint(0, 100)
            if random.randint(0, 100) < self.votepercentage:
                self.playreason = "SCORED"
                return random.choice(self.scorelist)
        chosen = random.choice(self.filelist)
        if self.__test_blacklist(chosen):
            self.__playlog(self.__gettime() + " BLACKLIST " + chosen )
            try:
                return self.__choose_file()
            except RuntimeError:
                log.debug("recursion error! too many matches from blacklist!")
                self.playreason = "BLACKLISTFORCED"
                return chosen
        self.playreason = "PLAYLIST"
        return chosen

    def __votelist_sort(self, a, b):
        if a[1] < b[1]:
            return 1
        elif a[1] > b[1]:
            return -1
        else:
            return 0

    def __write_votelist(self):
        log.debug("writing votelist")
        if self.mode == "vote":
            if len(self.votelist) != 0:
                vfile = open(self.basedir + "/votes", 'w')
                for entry in self.votelist:
                    vfile.write(entry[0] + "," + str(entry[1]) + "\n")
                    log.debug("in votelist: " + entry[0])
                vfile.close()
            else:
                if os.access(self.basedir + "/votes", os.F_OK):
                    os.remove(self.basedir + "/votes")
        log.debug("done writing votelist")
    
    def __gettime(self):
        d = datetime.datetime(1,2,3)
        return d.today().strftime("%Y%m%d-%H%M")

    def __done(self):
        log.debug("done playing")
        if not self.doExit:
            if self.filetoplay != "":
                self.__playlog(self.__gettime() + " " + self.nextreason +" " + self.filetoplay )
            self.nextreason = "DONE"
            if len(self.votelist) != 0:
                self.filetoplay = self.votelist[0][0]
                self.__playlog(self.__gettime() + " " + self.votelist[0][2] + " " + self.filetoplay )
                self.votelist = self.votelist[1:]
            elif not self.doNotSwitch:
                self.filetoplay = self.nextfiletoplay
                self.__playlog(self.__gettime() + " " + self.playreason + " " + self.filetoplay )
                self.chooseFile()
                self.hist_pointer = len(self.history)
            self.doNotSwitch = False
            self.__write_votelist()
            time.sleep(2)
            log.debug("attempting to play file " + self.filetoplay)
            self.play(self.filetoplay)
 
    def __playlog(self, s):
        if self.playlist_changed != "":
            pl = self.playlist_changed
            self.playlist_changed = ""
        else:
            pl = self.playlist
        plfile = open(self.savedir + "/logs/" + pl, 'a')
        plfile.write(s + "\n")
        plfile.close()

    def initConfig(self):
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
        self.votepercentage = int(self.config["voteplay"].rstrip("/"))
        self.scoressize = int(self.config["maxscored"])
        self.controlfile = self.basedir + "/control"

        for t in self.config["filetypes"].split(","):
            self.filetypes[t] = self.config[t]

    def chooseFile(self):
        log.debug("choose next file to play")
        self.nextfiletoplay = self.__choose_file()
        nfile = open(self.basedir + "/nextfile", 'w')
        nfile.write(self.nextfiletoplay + "\n")
        nfile.close()

    def buildPlaylist(self, dir):
        log.debug("building playlist")
        fl = []
        for root, dirs, files in os.walk(self.mediadir, topdown=False):
            for name in files:
                if name[name.rfind(".")+1:] in self.filetypes.keys():
                    fl.append(os.path.join(root, name).rstrip())
        lfile = open(self.listdir + "/" + self.playlist, 'w')
        for line in fl:
            lfile.write(line + "\n")
        lfile.close()
        if self.playlist == "default":
            self.filelist = fl
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

        self.__write_scores()

        # stop playthread 
        if oyster.playerid != 0:
            os.kill(oyster.playerid, signal.SIGQUIT)
        self.__playlog(self.__gettime() + " QUIT " + self.filetoplay )  
        sys.exit()

    def play(self, f):
        if self.filetoplay != "":
            log.debug("playing " + f)
            suffixpos = f.rfind(".")
            player = self.filetypes[f[suffixpos+1:]]
            self.history.append(f)
            self.__write_history()
            self.playerid = os.spawnl(os.P_NOWAIT, player, player, f)
            pfile = open(self.basedir + "/info", 'w')
            pfile.write(f + "\n")
            pfile.close()
            os.waitpid(self.playerid, 0)
        self.__done()

    def playPrevious(self):
        if self.hist_pointer > 0:
            self.hist_pointer -= 1
            self.filetoplay = self.history[self.hist_pointer]
            self.doNotSwitch = True
            self.next()

    def next(self):
        self.nextreason = "SKIPPED"
        if self.playerid != 0:
            os.kill(self.playerid, signal.SIGQUIT)

    def pause(self):
        self.paused = True
        pfile = open(self.basedir + "/status", 'w')
        pfile.write("paused")
        pfile.close()
        if self.playerid != 0:
            os.kill(self.playerid, signal.SIGSTOP)
    
    def unpause(self):
        self.paused = False
        pfile = open(self.basedir + "/status", 'w')
        pfile.write("playing")
        pfile.close()
        if self.playerid != 0:
            os.kill(self.playerid, signal.SIGCONT)

    def enableFavmode(self):
        if len(self.scorelist) != 0:
            self.votepercentage = 100
        favfile = open(self.basedir + "/favmode", 'w')
        favfile.write("on\n")
        favfile.close()

    def disableFavmode(self):
        self.votepercentage = self.config["voteplay"]
        favfile = open(self.basedir + "/favmode", 'w')
        favfile.write("off\n")
        favfile.close()

    def enqueue(self, f, reason):
        if self.mode == "vote":
            for tup in self.votelist:
                if tup[0] == f:
                    tup[1] += 1
                    return
            self.votelist.append( [f, 1, reason] ) 
            self.__write_votelist()

    def vote(self, f, reason):
        if self.mode == "vote":
            self.enqueue(f, reason)
            self.scoreup(f)

    def scoreup(self, f):
        log.debug("scoreup")
        self.scorepointer += 1
        if self.scorepointer == self.scoressize:
            self.scorepointer = 0
        self.scorelist.append(f)
        self.__write_scores()
        log.debug("scoreup done")

    def scoredown(self, f):
        try:
            self.scorelist.remove(f)
            self.scorepointer -= 1
            if self.scorepointer < 0:
                self.scorepointer = 0
            self.__write_scores()
        except ValueError:
            pass

    def dequeue(self, f):
        for tup in self.votelist:
            if f == tup[0]:
                self.votelist.remove(tup)
                return tup
        return None

    def unvote(self, f):
        tup = self.dequeue(f)
        if tup != None:
            if tup[2] == "VOTED":
                for i in range(1, tup[1]):
                    self.scoredown()
        self.__write_votelist()

    def enqueueList(self, f):
        try:
            lfile = open(f, 'r')
        except IOError:
            pass
        listpath = f[:f.rfind("/")]
        for line in lfile.readlines():
            posHash = line.find('#')
            if (posHash != -1) and (line[:(posHash)] == " "*(posHash+1)) :
                continue
            posSlash = line.find("/")
            if posSlash == 0:
                self.enqueue(line.rstrip())
            elif posSlash == -1:
                self.enqueue(listpath + "/" + line.rstrip())

    def loadPlaylist(self, listname):
        if os.access(self.listdir + "/" + listname, os.R_OK):
            deflist = open(self.listdir + "/" + listname, 'r')
            self.filelist = []
            self.playlist_changed = self.playlist
            self.playlist = listname
            self.scoresfile = self.savedir + "/scores/" + self.playlist
            self.__update_scores()
            self.__write_playlist_status()
            for line in deflist.readlines():
                # self.filelist.append(line.rstrip())
                self.filelist.append(line.rstrip())
        self.chooseFile()

class ControlThread(threading.Thread):
    def startController(self, o, cfile):
        self.oyster = o
        self.controlfile = cfile
        self.start()
    def run(self):
        while 1:
            self.readControl()
    def readControl(self):
        commandline = self.controlfile.readline().rstrip()
        cpos = commandline.find(" ")
        if cpos == -1:
            command = commandline
        else:
            command = commandline[:cpos]

        log.debug("command: " + command)

        if command == "NEXT":
            oyster.next()
        elif command == "QUIT":
            oyster.exit()
        elif command == "PAUSE":
            if not self.paused:
                oyster.pause()
            else:
                oyster.unpause()
        elif command == "UNPAUSE":
            oyster.unpause()
        elif command == "PREV":
            oyster.playPrevious()
        elif command == "VOTE":
            oyster.vote(commandline[cpos+1:], "VOTED")
        elif command == "ENQUEUE":
            oyster.enqueue(commandline[cpos+1:], "ENQUEUED")
        elif command == "DEQUEUE":
            oyster.dequeue(commandline[cpos+1:])
        elif command == "UNVOTE":
            oyster.unvote(commandline[cpos+1:])
        elif command == "SCORE":
            if commandline[cpos+1:cpos+2] == "+":
                oyster.scoreup(commandline[cpos+3:])
            elif commandline[cpos+1:cpos+2] == "-":
                oyster.scoredown(commandline[cpos+3:])
        elif command == "ENQLIST":
            oyster.enqueueList(commandline[cpos+1:])
        elif command == "RELOADCONFIG":
            oyster.initConfig()
        elif command == "FAVMODE":
            oyster.enableFavmode()
        elif command == "NOFAVMODE":
            oyster.disableFavmode()
        elif command == "LOAD":
            oyster.loadPlaylist(commandline[cpos+1:])
        
class PlaylistBuilder(threading.Thread):
    oyster = None
    def buildPlaylist(self, o):
        self.oyster = o
        self.start()
    def run(self):
        self.oyster.buildPlaylist(self.oyster.mediadir)

if __name__ == '__main__':
    logging.config.fileConfig("oysterlog.conf")
    log = logging.getLogger("oyster")
    oyster = Oyster()
    oyster.play(oyster.filetoplay)
