#!/bin/sh

BASEDIR="/tmp/oyster";

echo "next" >> $BASEDIR/control

perl oyster-gui.pl
