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

import string
import os

def get_values(filename):

    readconfig = get_defaults()
    conffile = file(filename)

    for line in conffile:
        if line[0] in string.letters:
            key, value = string.split(line[:-1], '=')
            if (key[-3:] == 'dir') & (value[-1:] != '/'):
                value = value + '/'
            readconfig[key] = value

    conffile.close()
    
    return readconfig


def get_defaults():

    config = { "savedir": os.getcwd() + "/",
               "basedir": "/tmp/oyster/",
               "mediadir": "/",
               "voteplay": "10",
               "filetypes": "mp3,ogg",
               "mp3": "/usr/bin/mpg123",
               "ogg": "/usr/bin/ogg123",
               "len_nextfiles": "5",
               "control_mode": "0600",
               "theme": "default",
               "maxscored": "30",
               "coverfilenames": "../${album}.png,../${album}.jpg",
               "coverwidth": "150",
               "encoding": "utf-8",
               "tagencoding": "de_DE.UTF-8"
              }

    return config


def get_config():

    # First, read default values

    if os.path.exists('config/default'):
        config = get_values('config/default')
    else:
        # There is no config-file, use builtin defaults
        config = get_defaults()

    # Then, read playlist-config if existing
    
    if os.path.isfile(config['basedir'] + 'playlist'):
        fifo = file(config['basedir'] + 'playlist')
        playlist = fifo.readline()[:-1]
        fifo.close()

        if playlist != 'default' and \
            os.path.exists(config['savedir'] + 'config/' + playlist):

            plconfig = get_values(config['savedir'] + 'config/' + playlist)

            for plkey in plconfig.keys():
                config[plkey] = plconfig[plkey]

    return config
  

def get_playlist():

    config = get_config()
    playlist = 'default'

    if os.path.isfile(config['basedir'] + 'playlist'):
        fifo = file(config['basedir'] + 'playlist')
        playlist = fifo.readline()[:-1]
        fifo.close()
	
    return playlist
