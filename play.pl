#!/usr/bin/perl

my $basedir = "/tmp/oyster";
my $mp3_player = "mpg321 -q";
my $ogg_player = "ogg123 -q";


open(FILENAME, "/tmp/oyster/kidplay");
$file = <FILENAME>;
close(FILENAME);
$file =~ /.*\.([^\.]*$)/;

$suffix = $1;
chop($suffix);
chop($file);

if ( $suffix eq "mp3" ){
  $command = $mp3_player . ' ' . '"' . $file . '"';
}
elsif ( ($suffix eq "ogg") ) {
  $command = $ogg_player . ' ' . '"' . $file . '"';
}

system ($command);

#CONTROL_OUT ist eine named pipe! open blockt!
open(CONTROL_OUT, ">$basedir/control");
print CONTROL_OUT "done\n";
close(CONTROL_OUT);
