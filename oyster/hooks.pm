
package oyster::hooks;

use strict;
use warnings;
use oyster::conf;
use Cwd;

my %config;
my $conffile = cwd() . "/oyster.conf";
my $preplayhooks = " ";
my $postplayhooks = " ";
my $savedir;

sub init {
	%config = oyster::conf->get_config($conffile);
	if ( $config{use_hooks} =~ /true/i ) {
		$savedir = $config{savedir};
		
		my @files = <$savedir/hooks/postplay/*>;
		foreach my $file (@files) {
			print STDERR $file . "\n";
			open ( PREPLAY, $file );
			while (my $line = <PREPLAY>) {
				chomp($line);
				$postplayhooks .= $line;
			}
			close ( PREPLAY );
		}
		
		@files = <$savedir/hooks/preplay/*>;
		foreach my $file (@files) {
			open ( PREPLAY, $file );
			while (my $line = <PREPLAY>) {
				chomp($line);
				$preplayhooks .= $line;
			}
			close ( PREPLAY );
		}
	}
}

sub postplay {
	my $played_file = $_[1];
	chomp $played_file;
	my $endreason = $_[2];
	eval $postplayhooks;
}

sub preplay {
	my $played_file = $_[1];
	chomp $played_file;
	my $playreason = $_[2];
	eval $preplayhooks;
}

1;
