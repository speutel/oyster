#!/usr/bin/python

# http://post.audioscrobbler.com/?hs=true&p=1.2&c=<client-id>&v=<client-ver>&u=<user>&t=<timestamp>&a=<auth>

import time, hashlib, urllib
import magic, mutagen.mp3, mutagen.easyid3, mutagen.oggvorbis, taginfo
import logging, logging.config
import threading
import lastfm

logging.config.fileConfig("oysterlog.conf")                                                                
log = logging.getLogger("scrobbler")

class Scrobbler: 

    user = None
    password = None

    session_id = None
    np_url = ""
    submit_url = ""
    status = "OK"
    submission_list = []

    scrobble = False

    def __init__(self, user, password):
        self.user = user
        self.password = password
        self.scrobble = True

        
        self.ms = magic.open(magic.MAGIC_MIME)
        self.ms.load()
        
        self.handshake(user, password)

    def request(self, url, body=""):
        ret = []

        try:
            log.debug("__request: %s\n" % (url))
            url = urllib.urlopen(url, body)
            ret = [r.rstrip() for r in url.readlines()]
            if ret[0] == "OK":
                return tuple(ret)
        except Exception, e:
            ret = [e]
        return (ret[0], None, None, None)


    def handshake(self, user, password):
        tstamp = str(int(time.time()))
        hash1 = hashlib.md5()
        hash1.update(password)
        pw_hd = hash1.hexdigest()
        hash2 = hashlib.md5()
        hash2.update(pw_hd + tstamp)
        auth = hash2.hexdigest()
        url = "?hs=true&p=1.2&c=tst&v=1.0&u=%s&t=%s&a=%s"%(user, tstamp, auth)
        url = "http://post.audioscrobbler.com/" + url
        ret = self.request(url)
        (self.status, self.session_id, self.np_url, self.submit_url) = ret
        if self.status != "OK":
            log.error("handshake problem: %s" % self.status)
            if self.status.startswith("BAD"):
                self.scrobble = False
        return ret

    def get_info(self, filename):
        artist = title = album = length = track = ""

        mimetype = self.ms.file(filename)
        if mimetype == 'application/ogg':
            tags = mutagen.oggvorbis.OggVorbis(filename)
            length = str(int(tags.info.length))
        elif mimetype == 'audio/mpeg':
            tags = mutagen.mp3.MP3(filename, ID3=mutagen.easyid3.EasyID3)
            length = str(int(tags.info.length))
        else:
            tags = taginfo.get_tag(filename)
            length = tags.get("playtime")
            parts = ":".split(length)
            try:
                length = str(int(parts[0]*60) + int(parts[1]))
            except:
                length = ""

        album = tags.get("album")
        if album is not None:
            album = album[0]
        artist = tags.get("artist")
        if artist is not None:
            artist = artist[0]
        title = tags.get("title")
        if title is not None:
            title = title[0]
        track = tags.get("tracknumber")
        if track is not None:
            track = track[0]
        return (artist, title, album, length, track)

    def nowplaying(self, filename=None, artist="", trackname="", album="", length="", tracknumber="", mbid="", track=None):
        if not self.scrobble:
            return
        if filename is not None and track is None:
            (artist, trackname, album, length, tracknumber) = self.get_info(filename)

        if track is None:
            track = Track(artist, trackname, album, length, tracknumber, mbid, int(time.time()))
        self.submission_list.append(track)

        NowPlaying(self, track).start()

    def submitAll(self):
        Submit(self).start()
       

class NowPlaying(threading.Thread):
    def __init__(self, lastfm, track):
        self.track = track
        self.session_id = lastfm.session_id
        self.lastfm = lastfm
        threading.Thread.__init__(self)

    def run(self):
        track = self.track
        #s=<sessionID>
            #The Session ID string as returned by the handshake. Required.
        #a=<artist>
            #The artist name. Required.
        #t=<track>
            #The track name. Required.
        #b=<album>
            #The album title, or empty if not known.
        #l=<secs>
            #The length of the track in seconds, or empty if not known.
        #n=<tracknumber>
            #The position of the track on the album, or empty if not known.
        #m=<mb-trackid>
            #The MusicBrainz Track ID, or empty if not known.  
        properties = {
                        "s": self.lastfm.session_id, 
                        "a": track.artist, 
                        "t": track.trackname, 
                        "b": track.album, 
                        "l": str(track.length), 
                        "n": track.tracknumber, 
                        "m": track.mbid
                    }
        log.debug("nowplaying: %s\n" % (properties))
        params = urllib.urlencode(properties, 1)
        counter = 3
        while counter > 0:
            ret = self.lastfm.request(self.lastfm.np_url, body=params)
            if ret[0] == "BADSESSION":
                ret = self.lastfm.handshake(self.lastfm.user, self.lastfm.password)
                return self.run()
            elif ret[0] != "OK":
                counter -= 1
            else:
                break
            
class Submit(Scrobbler, threading.Thread):
    def __init__(self, lastfm):
        self.lastfm = lastfm
        threading.Thread.__init__(self)

    def run(self):
        tmplist = self.lastfm.submission_list
        self.lastfm.submission_list = []

        for track in tmplist:
            self.submit(track)

    def submit(self, track, errorhandling=True):
        if not self.lastfm.scrobble:
            return

        properties = {
                        "s": self.lastfm.session_id, 
                        "a[0]": track.artist, 
                        "t[0]": track.trackname, 
                        "b[0]": track.album, 
                        "l[0]": str(track.length), 
                        "n[0]": track.tracknumber, 
                        "m[0]": track.mbid, 
                        "i[0]": track.playtime, 
                        "o[0]": "P", 
                        "r[0]": ""
        }
        log.debug("submit: %s\n" % (properties))
      
        # only submit if track is longer than 30 seconds and was played half or longer than 240 seconds
        if int(track.length) < 30:
            return
        offset = int(track.length)/2
        if offset > 240:
            offset = 240
        tstamp = int(time.time()) 
        sec_played = tstamp - int(track.playtime)
        if sec_played < offset:
            log.info("won't submit '%s - %s' - track was only played for %i seconds" % (track.artist, track.trackname, sec_played ))
            return
        else:
            log.info("submitting '%s - %s' - track was played for %i seconds" % (track.artist, track.trackname, sec_played))

        params = urllib.urlencode(properties, 1)

        counter = 3
        while counter > 0:
            ret = self.lastfm.request(self.lastfm.submit_url, body=params)
            if ret[0] == "BADSESSION":
                log.debug("badsession -> handshake")
                ret = self.lastfm.handshake(self.lastfm.user, self.lastfm.password)
                return self.submit(track=track)
            elif ret[0] == "OK":
                log.debug("submitted %s - %s" % (track.artist, track.trackname))
                return None
            else:
                counter -= 1

        # re-handshake?
        if counter == 0:
            self.lastfm.handshake(self.lastfm.user, self.lastfm.password)
            if errorhandling:
                self.submit(track, False)
                log.debug("submitted %s - %s" % (track.artist, track.trackname))
            else:
                self.lastfm.submission_list.append(track)
                log.debug("could not submit %s - %s" % (track.artist, track.trackname))

class Track:
    def __init__(self, artist, trackname, album, length, tracknumber, mbid, playtime):
        self.artist = artist
        self.trackname = trackname
        self.album = album
        self.length = length
        self.tracknumber = tracknumber
        self.mbid = mbid
        self.playtime = playtime
