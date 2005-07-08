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

def get_config(filename):

    config = {}
    conffile = file(filename)

    for line in conffile:
        if line[0] in string.letters:
            key, value = string.split(line[:-1], '=')
            if (key[-3:] == 'dir') & (value[-1:] != '/'):
                value = value + '/'
            config[key] = value

    conffile.close()

    return config
  

def get_playlist():

    config = get_config('oyster.conf')
    playlist = 'default'

    if os.path.isfile(config['basedir'] + 'playlist'):
        fifo = file(config['basedir'] + 'playlist')
        playlist = fifo.readline()[:-1]
        fifo.close()
	
    return playlist
