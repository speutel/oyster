#!/usr/bin/perl

my $basedir = "/tmp/oyster";

open(CONTROL, ">>$basedir/control");
print CONTROL 'next';
close(CONTROL);
