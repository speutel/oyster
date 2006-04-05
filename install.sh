#!/bin/sh

MKDIR=`which mkdir`
CP=`which cp`
CHMOD=`which chmod`

# Testing python

PYTHON=`which python`

echo -n "Searching for python... "

if [ $PYTHON ]
then
 echo found!
else
 echo not found!
 echo
 echo Oyster is a CGI-script based on python. This script was
 echo unable to locate the python-binary in the given path.
 echo If python is installed but not in your path, you may
 echo proceed anyway.
 echo
 echo -n "Do you want to continue? [y/N] "
 read ANSWER
 if [[ ! $ANSWER == 'y' && ! $ANSWER == 'Y' ]]
 then
  exit 0
 else
  echo
 fi
fi

# Testing players

MPG123=`which mpg123`
OGG123=`which ogg123`

echo -n "Searching for audio players... "

if [[ $MPG123 && $OGG123 ]]
then
 echo found!
else
 echo not found!
 echo

 # Testing mpg123

 if [ ! $MPG123 ]
 then
  echo mpg123 is needed to play MP3-files, but
  echo it could no be found. If you want to use another
  echo player, you have to specify this in the default configuration
  echo
  echo -n "Do you want to continue? [y/N] "
  read ANSWER
  if [[ ! $ANSWER == 'y' && ! $ANSWER == 'Y' ]]
  then
   exit 0
  else
   echo
  fi
 fi

 # Testing ogg123

 if [ ! $OGG123 ]
 then
  echo ogg123 is needed to play Vorbis-files, but
  echo it could no be found. If you want to use another
  echo player, you have to specify this in the default configuration
  echo
  echo -n "Do you want to continue? [y/N] "
  read ANSWER
  if [[ ! $ANSWER == 'y' && ! $ANSWER == 'Y' ]]
  then
   exit 0
  else
   echo
  fi
 fi 
fi

# Testing aumix

AUMIX=`which aumix`

echo -n "Searching for aumix... "

if [ $AUMIX ]
then
 echo found!
else
 echo not found!
 echo
 echo aumix is needed for oyster to control the mixer of the
 echo soundcard. If you want to use another program than aumix
 echo you have to specify this in control.py
 echo
 echo -n "Do you want to continue? [y/N] "
 read ANSWER
 if [[ ! $ANSWER == 'y' && ! $ANSWER == 'Y' ]]
 then
  exit 0
 else
  echo
 fi
fi

# Choosing destination directory

echo
echo -n "In which directory should Oyster be installed? [/var/www/oyster] "
read PATH
if [[ $PATH == "" ]]
then
 PATH="/var/www/oyster"
fi

$MKDIR -p $PATH

if [ ! -e $PATH ]
then
 echo Unable to create $PATH
 exit 1
fi

echo
echo -n "Copying files... "

# Copying files

$CP *.py $PATH
$CP -r themes $PATH
$CP index.html $PATH

echo done.

$CHMOD u+x $PATH/*.py

echo
echo Installation mostly finished.
echo What YOU have to do now is:
echo
echo 1. Change owner of the files to the user which runs oyster
echo "   (usually www-data)"
echo 2. Give this user the permission to write to your audio device.
echo 3. Configure your apache to execute those scripts.
echo 4. Start your browser and point it to http://servername/oyster
echo 5. Use \"Extras / Configuration Editor\"
echo 6. Test your configuration with the \"configuration checker\" on the left
echo 7. Have fun using Oyster!
echo
