#!perl
# we can't use -T because Net::SSH::Perl has a problem
# dammit

# we're testing if we can connect
use Test::More tests => 2;
use Test::SFTP;

use strict;
use warnings;

my $EMPTY    = q{};
$ENV{'HOME'} = $EMPTY;

my $sftp = Test::SFTP->new(
    host     => '1.2.3.4',
    user     => 'Sir lancelot',
    password => 'valuez',
    timeout  => 5,
);

$sftp->cannot_connect('cannot connect to SFTP');
is( $sftp->connected, 0, 'we are really not connected' );

