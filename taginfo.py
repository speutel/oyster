#!/usr/bin/python
# -*- coding: UTF-8 -*
# oyster - a python-based jukebox and web-frontend
#
# Copyright (C) 2004 Benjamin Hanzelmann <ben@nabcos.de>,
# Stephan Windmüller <windy@white-hawk.de>,
# Stefan Naujokat <git@ethric.de>
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
import anydbm
import string
import cgi
import os
import re

myconfig = config.get_config()
playlist = config.get_playlist()


def get_tag_light(filename):

    cache = anydbm.open(myconfig['savedir'] + 'tagcache-python', 'c')
    tag = {}
     
    if filename in cache:
        tag['display'] = cache[filename]
        cache.close()
    else:
        cache.close()
        tag = get_tag(filename)
    
    return tag['display']


def get_tag(filename):

    tag = {'title': ''}

    if (filename[-3:]).lower() == 'mp3':
        tag = get_mp3_tags(filename)
    elif (filename[-3:]).lower() == 'ogg':
        tag = get_ogg_tags(filename)
    elif (filename[-4:]).lower() == 'flac':
        tag = get_ogg_tags(filename)

    # Count current score

    tag['score'] = get_score(filename)

    tag['display'] = get_display(filename, tag)

    cache = anydbm.open(myconfig['savedir'] + 'tagcache-python', 'c')
    cache[filename] = tag['display']
    cache.close()

    return tag


def get_display(filename, tag):

    if not 'title' in tag or tag['title'] == '':
        filename = os.path.basename(filename)[:-4]
        display = filename
    elif not 'artist' in tag or tag['artist'] == '':
        display = tag['title']
    else:
        display = tag['artist'] + ' - ' + tag['title']

    return display


def get_score(filename):

    score = 0
    scorefile = myconfig['savedir'] + 'scores/' + playlist
     
    if os.path.isfile(scorefile):
        lastopen = file(scorefile)
        for line in lastopen:
            if line[:-1] == filename:
                score += 1
        lastopen.close()

    return score


def get_mp3_tags(filename):

    tag = {'format': 'MP3'}
    filename = filename.replace("`", "\`")
    filename = filename.replace('"', '\\"')
    os.environ['LANG'] = myconfig['tagencoding']
    mp3 = os.popen('id3v2 -l "' + filename + '"').readlines()

    mp3_regex = (
        ('\ATitle[\s]*:[\s]*(.*)\Z',                     'title'),    # id3v2, old version. Order does matter!
        ('\ATitle\ \ \:\ (.*)Artist\:',                  'title'),    # id3v1, overrides above if found
        ('\ATitle\ \ \:\ .*Artist\:\ (.*)',              'artist'),   # id3v1, overrides above if found
        ('\ALead\ .*\:\ (.*)\Z',                         'artist'),
        ('\AAlbum\ \ \ \:\ (.*)Year\:\ ',                'album'),
        ('\AAlbum\ \ \ \:\ .*Year\:\ ([0-9]*),\ Genre\:\ ', 'year'),
        ('\AAlbum\ \ \ \:\ .*Year\:\ [0-9]*,\ Genre\:\ (.*)\Z', 'genre'),
        ('\AAlbum\/Movie\/Show\ title\:\ (.*)\Z',        'album'),
        ('\ATALB\ \(.*\)\:\ (.*)\Z',                     'album'),
        ('\AYear\:\ ([0-9]*)',                           'year'),
        ('\AContent\ type\:\ \([0-9]*\)(.*)',            'genre'),
        ('\AComment.*Track\:\ ([0-9]*)',                 'track'),
        ('\ATrack\ number\/Position\ in\ set\:\ (.*)\Z', 'track'),
        ('\ALength\:\ (.*)\Z',                           'playtime'),
        ('\ATIT2\ \(.*\)\:\ (.*)\Z',                     'title'),
        ('\ATPE1\ \(.*\)\:\ (.*)\Z',                     'artist'),
        ('\ATYER\ \(Year\)\:\ (.*)\Z',                   'year'),
        ('\ATCON\ \(.*\)\:\ (.*)\ \([0-9]*\)',           'genre'),
        ('\ATRCK\ \(.*\)\:\ (.*)\Z',                     'track'),
        ('\ATLEN\ \(.*\)\:\ (.*)\Z',                     'playtime')
    )
        
    for line in mp3:
        for regex in mp3_regex:
            matcher = re.match(regex[0], line[:-1])
            if matcher is not None:
                tag[regex[1]] = cgi.escape(unicode(matcher.group(1).rstrip(), 'latin-1').encode(myconfig['encoding']))

    try:
        if tag['playtime'] != '':
            playtimeminutes = int(int(tag['playtime']) / 1000 / 60)
            playtimeseconds = int(int(tag['playtime']) / 1000 % 60)
            if playtimeseconds < 10:
                playtimeseconds = '0' + str(playtimeseconds)
            
            tag['playtime'] = str(playtimeminutes) + ':' + str(playtimeseconds)
    except KeyError:
        pass
    
    return tag


def get_ogg_tags(filename):

    filename = filename.replace("`", "\`")
    filename = filename.replace('"', '\\"')

    os.environ['LANG'] = myconfig['tagencoding']
    
    tag = {}

    if (filename[-3:]).lower() == 'ogg':
        tag['format'] = 'OGG Vorbis'
        ogg = os.popen('ogginfo "' + filename + '"')
    elif (filename[-4:]).lower() == 'flac':
        tag['format'] = 'FLAC'
        ogg = os.popen('metaflac --export-tags-to=- "' + filename + '"')
    else:
        ogg = []

    ogg_regex = {
        'title=(.*)':                 'title',
        'artist=(.*)':                'artist',
        'album=(.*)':                 'album',
        'date=(.*)':                  'year',
        'genre=(.*)':                 'genre',
        'tracknumber=(.*)':           'track',
        'comment=(.*)':               'comment',
        'playback\ length:\ (.*)':    'playtime'
    }

    for line in ogg:
        line = line.lstrip()
        for regex in ogg_regex:
            matcher = re.match(regex, line, re.I)
            if matcher is not None:
                tag[ogg_regex[regex]] = cgi.escape(matcher.group(1).rstrip())

    try:
        transtable = string.maketrans(string.digits + ":", string.digits + ":")
        tag['playtime'] = tag['playtime'].translate(transtable, string.letters)[:-4]
    except KeyError:
        pass

    return tag
