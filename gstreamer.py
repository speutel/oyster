# -*- coding: UTF-8 -*-
import threading
import pygst
pygst.require("0.10")
import gst

__author__ = 'benjamin@hanzelmann.de'

class GStreamer(object):
    def __init__(self):
        self.__lock = threading.Condition()


#        self.player = gst.element_factory_make("playbin2", "player")
#        converter = gst.element_factory_make("audioconvert", "converter")
#        rg = gst.element_factory_make("rgvolume", "rg")
#
#        gst.element_link_many(self.player, converter, rg)
#
#        sink = gst.element_factory_make("pulsesink", "sink")
#        self.player.set_property("audio-sink", sink)


    def on_message(self, bus, message):
        print "on_message"
        t = message.type
        print t
        if t == gst.MESSAGE_EOS:
            self.stop()
        elif t == gst.MESSAGE_ERROR:
            err, debug = message.parse_error()
            print err
            print debug
            self.stop()



    def play(self, file):
        uri = "file://" + file
        self.player = gst.parse_launch("playbin2 uri=%s| audioconvert | rgvolume | pulsesink" %(uri,))
#        self.player.set_property("uri", uri)
        self.player.set_state(gst.STATE_PLAYING)
        self.bus = self.player.get_bus()
        self.bus.add_signal_watch()
        self.bus.connect("message", self.on_message)
        # block until done
        while self.player.get_state() == gst.STATE_PLAYING:
            time.sleep(1)

    def unlock(self):
        self.__lock.acquire( )
        self.__lock.notifyAll( )
        self.__lock.release( )

    def stop(self):
        self.player.set_state(gst.STATE_NULL)
        self.bus.disconnect()
        self.bus = None
        self.unlock( )

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
            gs.play("test_music/2.ogg")

    print "play"
    PlayThread().start()
    import time
    time.sleep(20)
