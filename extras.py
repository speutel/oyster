#!/usr/bin/python
# -*- coding: UTF-8 -*-

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

"""Print a static page containing links of the Extras-section"""

__revision__ = 1

import cgitb
cgitb.enable()

import common

common.hide_page_in_party_mode()
common.navigation_header(title="Extras")

print "<h1><a href='playlists.py'>Playlists</a></h1>"
print "<div style='padding-left: 2em;'>"
print "Manage or select playlist</div>"

print "<h1><a href='score.py'>Scoring</a></h1>"
print "<div style='padding-left: 2em;'>Specify which songs should be played more often</div>"

print "<h1><a href='blacklist.py'>Blacklists</a></h1>"
print "<div style='padding-left: 2em;'>"
print "Specify files (e.g. audio books) which should never be played</div>"

print "<h1><a href='statistics.py'>Statistics</a></h1>"
print "<div style='padding-left: 2em;'>"
print "Print general statistics like Top-10-Songs, number of played songs, " + \
    "number of all played songs etc.</div>"

print "<h1><a href='clearscores.py'>Clear Scorefile</a></h1>"
print "<div style='padding-left: 2em;'>"
print "Check your scorefile for files which have been deleted or renamend."
print "</div>"

print "<h1><a href='rebuildtags.py'>Rebuild taginfos</a></h1>"
print "<div style='padding-left: 2em;'>"
print "Rebuilds the tagcache in case you changed the tags of many files."
print "</div>"

print "<h1><a href='configedit.py'>Configuration Editor</a></h1>"
print "<div style='padding-left: 2em;'>"
print "Edit the global configuration file or change settings for a single playlist."
print "</div>"

print "<h1><a href='history.py'>History</a></h1>"
print "<div style='padding-left: 2em;'>"
print "Want to know which song was played at a specific time? Search the logs here!"
print "</div>"

print "</body></html>"
