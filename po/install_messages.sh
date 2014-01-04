#!/bin/bash

MSGFMT=/usr/share/doc/python2.7/examples/Tools/i18n/msgfmt.py

if [ ! -e ${MSGFMT} ]
then
    echo msgfmt.py not found, please install python examples
fi

${MSGFMT} -o de/LC_MESSAGES/oyster.mo de
${MSGFMT} -o en/LC_MESSAGES/oyster.mo en

echo New messages installed.
