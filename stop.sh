#!/bin/sh

source oyster.conf

echo "QUIT" >> $basedir/control

cat<<EOF
Content-Type: text/html; charset=ISO-8859-1

<html>
<head>
<meta http-equiv="refresh" content="0; URL=oyster-gui.pl">
</head>
<body><a href="oyster.html">Zur&uuml;ck</a></body>
</html>
EOF
