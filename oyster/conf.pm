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
			my ($key, $value) = split("=", $line);
			$config{$key} = $value;
		}
	}

	close(CONF);

	return %config;
}
