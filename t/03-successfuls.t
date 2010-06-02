#!perl

# we're testing if we can connect
use strict;
use warnings;

use English '-no_match_vars';
use Test::More tests => 14;
use Test::SFTP;
use Term::ReadLine;
use Term::ReadPassword;

SKIP: {
    eval "getpwuid $REAL_USER_ID";
    if ( $EVAL_ERROR ) {
        skip "no getpwuid", 14;
    }

    my $SPACE    = q{ };
    my $EMPTY    = q{};
    my $timeout  = 10;
    my $host     = 'localhost';
    my $username = getpwuid $REAL_USER_ID || $EMPTY;
    my $term     = Term::ReadLine->new('test_term');

    my ( $password, $test, $prompt );
    my ( $full_status, $status_number, $status_string );

    SKIP: {
        eval {
            local $SIG{'ALRM'} = sub {
                die "input failed\n";
            };

            alarm $timeout;

            print STDERR "\nI need your help for some tests.\n"              .
                         "Enter 'q' to quit the tests, or wait $timeout "    .
                         "seconds for me to just continue without testing\n" .
                         "You can press [enter] if you want to help me with" .
                         " this and test this module\n";
            $test = $term->readline('So? ');
            chomp $test;

            alarm 0;
        };

        if ( $EVAL_ERROR eq "input failed\n" || $test eq 'q' ) {
            skip "Alright, nevermind...\n", 14;
        }

        $prompt = $term->readline("SSH/SFTP host to test [$host]: ");
        $prompt and $host = $prompt;

        $prompt = $term->readline("Username [$username]: ");
        $prompt and $username = $prompt;

        # <3 IO::Prompt
        $password = read_password('Password: ');

        my $sftp = Test::SFTP->new(
            host     => $host,
            user     => $username,
            password => $password,
            timeout  => 2,
        );

        $sftp->can_connect('can connect to SFTP');
        is( $sftp->connected, 1, 'we are really connected' );

        ( $status_number, $status_string ) = ( '0', 'No error' );
        $full_status = join $SPACE, $status_number, $status_string;

        $sftp->is_status( $full_status, 'Checking SFTP no error complete status' );
        $sftp->is_status_number( $status_number, 'Checking SFTP no error status number' );
        $sftp->is_status_string( $status_string, 'Checking SFTP no error status string' );

        srand;

        SKIP: {
            if ( $ENV{'TEST_SFTP_DANG'} ) {
                skip "Dangerous tests only tests if TEST_SFTP_DANG is set", 2;
            }

            eval 'use File::Util';

            if ($EVAL_ERROR) {
                skip 'Missing File::Util', 2;
            }

            my $random_file = rand 99999;

            my $file_util = File::Util->new;
            $file_util->touch($random_file);

            $sftp->can_put( $random_file, $random_file, 'Trying to upload to good location' );
            $sftp->can_get( $random_file, 'Trying to get a file' );

            # this is dangerous, we need to finish some stuff before allowing people to run all these tests
            $sftp->object->do_remove( $random_file );

            # we do not need this file anymore
            # TODO: if in the process of getting a file we overwritten that file, we will be accidently removing it
            # so we need to check if it is so
            unlink $random_file;
        };

        my $random_file = rand 99999;
        my $bad_path    = "/$random_file";

        # TODO: OS portability
        $sftp->can_ls( '/', 'Trying to do ls'   );
        $sftp->cannot_ls( $bad_path, 'Trying to fail ls' );

        $sftp->cannot_put( $random_file, $bad_path, 'Trying to upload to bad location'  );
        $sftp->cannot_get( $bad_path, 'Trying to get a nonexistent file' );

        ( $status_number, $status_string ) = ( '2', 'No such file or directory' );
        $full_status = join $SPACE, $status_number, $status_string;

        $sftp->is_status( $full_status, 'Checking SFTP nonexistent path complete status' );
        $sftp->is_status_number( $status_number, 'Checking nonexistent path SFTP status number' );
        $sftp->is_status_string( $status_string, 'Checking nonexistent path SFTP status string' );

    }
}

