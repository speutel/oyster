# -*- coding: ISO-8859-1 -*-
import threading
import pygst
pygst.require("0.10")
import gst

__author__ = 'benjamin@hanzelmann.de'

class GStreamer(object):
    def __init__(self):
        self.__lock = threading.Condition()
        self.player = gst.element_factory_make("playbin2", "player")
        rg = gst.element_factory_make("rgvolume", "rg")
        gst.Bin.add(self.player, rg)

        sink = gst.element_factory_make("pulsesink", "sink")
        self.player.set_property("audio-sink", sink)

        self.bus = self.player.get_bus()
        self.bus.add_signal_watch()
        self.bus.connect("message", self.on_message)

    def on_message(self, bus, message):
        t = message.type
        print t
        if t == gst.MESSAGE_EOS:
            # wrap up
            self.player.set_state(gst.STATE_NULL)
            self.__lock.acquire()
            print "notifying gstreamer lock"
            self.__lock.notifyAll()
            self.__lock.release()
        elif t == gst.MESSAGE_ERROR:
            err, debug = message.parse_error()
            print err
            print debug
            self.player.set_state(gst.STATE_NULL)
            self.__lock.acquire()
            print "notifying gstreamer lock"
            self.__lock.notifyAll()
            self.__lock.release()



    def play(self, file):
        uri = "file://" + file
        self.player.set_property("uri", uri)
        self.player.set_state(gst.STATE_PLAYING)
        # block until done
        self.__lock.acquire()
        print "waiting on gstreamer lock"
        self.__lock.wait()
        self.__lock.release()

    def stop(self):
        self.player.set_state(gst.STATE_NULL)
        print "acquiring gstreamer lock"
        self.__lock.acquire()
        print "notifying gstreamer lock"
        self.__lock.notifyAll()
        self.__lock.release()

    def pause(self):
        self.player.set_state(gst.STATE_PAUSED)

    def unpause(self):
        self.player.set_state(gst.STATE_PLAYING)

    def __str__(self):
        return "GStreamer Player"

    def __repr__(self):
        return self.__str__()

if __name__ == "__main__":
    gs = GStreamer()
    class PlayThread(threading.Thread):
        def run(self):
            gs.play("/mnt/munin/download/Musik/Alben/3 Doors Down/3 Doors Down - Seventeen Days/01 - Right Where I Belong.mp3")

    print "play"
    PlayThread().start()
    import time
    #while gs.playmode:
    time.sleep(3)
    print "pause"
    gs.pause()
    time.sleep(3)
    print "cont"
    gs.unpause()
    time.sleep(3)
    print "stop"
    gs.stop()
