#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Test::SFTP' );
}

diag( "Testing Test::SFTP $Test::SFTP::VERSION, Perl $], $^X" );
