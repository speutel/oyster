#!/usr/bin/python
# -*- coding: UTF-8 -*-
# oyster - a python-based jukebox and web-frontend
#
# Copyright (C) 2004 Benjamin Hanzelmann <ben@nabcos.de>,
#  Stephan WindmÃ¼ller <windy@white-hawk.de>,
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

"""
index.py creates a frameset and allows the start at a specified site
(such as playlists.py)
"""

__revision__ = 1

import cgi
import cgitb
cgitb.enable()

form = cgi.FieldStorage()

if form.has_key('view'):
    validsites = ['blacklist', 'browse', 'configedit', 'extras', 'playlists', \
        'score', 'search']
    for validsite in validsites:
        if form['view'].value == validsite:
            view = validsite + '.py'
else:
    view = 'browse.py'


print """Content-Type: text/html; charset=utf-8

<?xml version='1.0' encoding='utf-8' ?>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN"
   "http://www.w3.org/TR/html4/frameset.dtd">
<html>
<head>
<title>Oyster</title>
<link rel='shortcut icon' href='themes/default/favicon.png'>
</head>
<frameset cols="*,*">
  <frameset rows="*,80">
   <frame src="oyster-gui.py" name="curplay">
   <frame src="control.py" name="control">
  </frameset>
"""
print"  <frame src='" + view + "' name='browse'>"
print """
    <noframes>
	<p>
	  Your browser does not seem to support display of frames.
	</p>
  </noframes>
</frameset>
</html>
"""
