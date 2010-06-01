#!perl

# we're testing if we can connect
use Test::More tests => 3;
use Test::SFTP;

use strict;
use warnings;

my $EMPTY    = q{};
$ENV{'HOME'} = $EMPTY;

my $sftp = Test::SFTP->new(
    host     => '1.2.3.4',
    user     => 'Sir lancelot',
    password => 'valuez',
    timeout  => 3,
);

is( $sftp->connected, 0, 'first connection failed' );
$sftp->cannot_connect('cannot connect to SFTP');
is( $sftp->connected, 0, 'we are really not connected' );

