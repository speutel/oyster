package oyster::conf;

use strict;
use warnings;

my %config;

my $VERSION = '1.0';
	
sub get_config {
	my $conffile = $_[1];

	open(CONF, $conffile) || die $!;
	
	while ( my $line = <CONF> ) {
		if ( $line =~ /^[a-z]/ ) {
		    chomp($line);
		    my ($key, $value) = split("=", $line);
		    if (($key eq 'mediadir') || ($key eq 'basedir') || ($key eq 'savedir')) {
					$value =~ s/\/$//;
					$value .= '/';
		    }
		    $config{$key} = $value;
		}
	}

	close(CONF);

	return %config;
}
