Oyster: Jukebox Software Written in Python
==========================================

Oyster is a jukebox software written in Python. It is meant to be installed on a
server which hosts music files and is equipped with a sound card. Users are able
to access the interface over a webbrowser.

Initially Oyster plays all songs at random. Users may create playlists or vote
for songs which are played next. Those votes will increase the scoring of the
repsective song, resulting in a higher propbability that the song will be played
at random when no more votes songs are present.

Features
--------

* Plays MP3, Ogg Vorbis, and FLAC files
* Supports playlists in M3U format
* Search function
* Scoring mechanism
* Arrange songs in playlists
* Option to blacklist single songs or entire directories
* Themable interface
* Statistics
* Open Source (GPL)

Requirements
------------

For oyster.py (the backend), you need mpg321 and/or ogg123 in $PATH.
For the GUI, you need an apache with the capability to execute python-CGI

Below you will find an example for the apache-config. It will allow
python-scripts to be executed.

    AddHandler cgi-script .cgi .sh .py

    [...]

    <Location /oyster>
         Options +ExecCGI
    </Location>

Installation
------------

Launch the install-script

 OR

Just untar oyster into a directory which is reachable to your
webserver. Now make sure that the webserver is able to read this
directory and its contents. Also it should be able to create new
files and directories here.

Configuration
-------------

Open the location http://servername/oyster in your browser. Here
you can edit your first configuration, test it and start oyster.

Enjoy
-----

That's it. Start oyster (via the GUI, or by hand with ``python oyster.py'') and
it will search in $mediadir for ogg and mp3 files, build a playlist and start
playing. 
