#!perl
# we're testing if we can connect
use Test::More tests => 1;
use Test::SFTP;
use English '-no_match_vars';

use strict;
use warnings;

SKIP: {
    eval 'use Test::Timer';

    if ($EVAL_ERROR) {
        skip 'Test::Timer not installed', 1;
    }

    my $SPACE    = q{ };
    my $EMPTY    = q{};
    my $timeout  = 3;
    my $host     = '1.2.3.4'; # lets hope no one uses it by accident
    my $username = 'user';
    my $password = 'pass';

    time_between( sub {
        Test::SFTP->new(
            host     => $host,
            user     => $username,
            password => $password,
            timeout  => $timeout,
        )->connect },
        $timeout,
        $timeout + 3,
        'Timeout is working',
    );
};

