#!/bin/bash

GETTEXT=/usr/share/doc/python2.7/examples/Tools/i18n/pygettext.py

if [ ! -e ${GETTEXT} ]
then
    echo pygettext.py not found, please install python examples
fi

${GETTEXT} ../*py

msgmerge de.po messages.pot > de.po.new
mv de.po.new de.po

msgmerge en.po messages.pot > en.po.new
mv en.po.new en.po

echo New messages merged.
