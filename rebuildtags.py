#!/usr/bin/python
# -*- coding: ISO-8859-1 -*-

# oyster - a perl-based jukebox and web-frontend
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

"Updates all cached Taginfos"

__revision__ = 1

import cgi
import config
import cgitb
import common
import anydbm
import os.path
import taginfo
cgitb.enable()

common.navigation_header()

myconfig = config.get_config()
mediadir = myconfig['mediadir'][:-1]
form = cgi.FieldStorage()
playlist = config.get_playlist()

cache = anydbm.open(myconfig['savedir'] + 'tagcache-python', 'c')
allfiles = cache.keys()
cache.close()

cache = anydbm.open(myconfig['savedir'] + 'tagcache-python', 'n')
cache.close()

print "<h1>Regeneration taginfos...</h1>"

for filename in allfiles:
    if os.path.exists(filename):
        print taginfo.get_tag_light(filename) + "<br>"

print "<h1>Done!</h1>"

print "</body></html>"
