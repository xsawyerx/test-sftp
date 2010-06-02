package Test::SFTP;

use strict;
use warnings;

use Carp;
use Moose;
use English '-no_match_vars';
use Test::Builder;
use Net::SFTP::Foreign;
use namespace::autoclean;

use parent 'Test::Builder::Module';

our $VERSION = '0.04';

# variables for the connection
has 'host'     => ( is => 'ro', isa => 'Str', required => 1 );
has 'user'     => ( is => 'ro', isa => 'Str' );
has 'password' => ( is => 'ro', isa => 'Str' );

has 'debug' => ( is => 'ro', isa => 'Int', default => 0 );
has 'warn'  => ( is => 'ro', isa => 'Int', default => 0 );

has 'more' => ( is => 'rw', isa => 'ArrayRef' );

# this holds the object itself. that way, users can do:
# $t_sftp->object->get() in a raw manner if they want
has 'object' => (
    is         => 'rw',
    isa        => 'Net::SFTP::Foreign',
    lazy_build => 1,
);

has 'connected'    => ( is => 'rw', isa => 'Bool', default => 0 );
has 'auto_connect' => ( is => 'rw', isa => 'Bool', default => 1 );

has 'timeout'      => ( is => 'ro', isa => 'Int' );

my $CLASS = __PACKAGE__;

sub _build_object {
    my $self = shift;
    my @more = ();
    my %opts = ();

    $self->user     and $opts{'user'}     = $self->user;
    $self->password and $opts{'password'} = $self->password;
    $self->more     and push @more, @{ $self->more };
    $self->debug    and push @more, '-v';

    if ( my $timeout = $self->timeout ) {
        $opts{'timeout'} = $timeout;
        push @more, '-o', "ConnectTimeout=$timeout";
    }

    my $object = Net::SFTP::Foreign->new(
        host => $self->host,
        more => \@more,
        %opts,
    );

    $object->error ? $self->connected(0) : $self->connected(1);

    return $object;
}

sub BUILD {
    my $self  = shift;
    my $EMPTY = q{};
    $self->object;
}

sub can_connect {
    my ( $self, $test ) = @_;
    my $tb = $CLASS->builder;

    $self->object( $self->_build_object );
    $tb->ok( ! $self->object->error(), $test );
}

sub cannot_connect {
    my ( $self, $test ) = @_;
    my $tb = $CLASS->builder;

    $self->object( $self->_build_object );;
    $tb->ok( $self->object->error, $test );
}

sub is_error {
    my ( $self, $error, $test ) = @_;
    my $tb = $CLASS->builder;

    $tb->is_eq( $self->object->error, $error, $test );
}

sub is_status {
    my ( $self, $status, $test ) = @_;
    my $tb = $CLASS->builder;

    $tb->is_eq( $self->object->status, $status, $test );
}

sub can_get {
    my ( $self, $local, $remote, $test ) = @_;
    my $tb    = $CLASS->builder;
    my $EMPTY = q{};

    $self->connected || $self->connect;

    $tb->ok( $self->object->get( $local, $remote ), $test );
}

sub cannot_get {
    my ( $self, $local, $remote, $test ) = @_;
    my $tb = $CLASS->builder;

    $self->connected || $self->connect;

    $tb->ok( !$self->object->get( $local, $remote ), $test );
}

sub can_put {
    my ( $self, $local, $remote, $test ) = @_;
    my $tb = $CLASS->builder;

    $self->connected || $self->connect;

    my $eval_error = eval { $self->object->put( $local, $remote ); };
    $tb->ok( $eval_error, $test );
}

sub cannot_put {
    my ( $self, $local, $remote, $test ) = @_;
    my $tb = $CLASS->builder;

    $self->connected || $self->connect;

    my $eval_error = eval { $self->object->put( $local, $remote ); };
    $tb->ok( !$eval_error, $test );
}

sub can_ls {
    my ( $self, $path, $test ) = @_;
    my $tb = $CLASS->builder;
    $self->connected || $self->connect;
    my $eval_error = eval { $self->object->ls($path); };
    $tb->ok( $eval_error, $test );
}

sub cannot_ls {
    my ( $self, $path, $test ) = @_;
    my $tb = $CLASS->builder;
    $self->connected || $self->connect;
    my $eval_error = eval { $self->object->ls($path); };
    $tb->ok( !$eval_error, $test );
}

no Moose;

1;

__END__

=head1 NAME

I<Test::SFTP> - An object to help test Net::SFTP

=head1 SYNOPSIS

    use Test::SFTP;

    my $t_sftp = Test::SFTP->new(
        host     => 'localhost',
        user     => 'sawyer',
        password => '2o7U!OYv',
        ...
    );

    $t_sftp->can_get( $remote_path, "Trying to get: $remote_path" );

    $t_sftp->can_put(
        $local_path,
        $remote_path,
        "Trying to copy $local_path to $remote_path",
    );

=head1 VERSION

This describes I<Test::SFTP> 0.04.

=head1 DESCRIPTION

Unlike most testing frameworks, I<Test::SFTP> provides an object oriented
interface. The reason is that it's simply easier to use an object than throw the
login information as command arguments each time. Maybe in time, there will be
another interface that will accept login information through global package
variables.

I<Test::SFTP> uses I<Net::SFTP> for the SFTP functions. This is actually a
testing framework for I<Net::SFTP>.

=head1 ATTRIBUTES

Basically there is almost complete corrolation with I<Net::SFTP> attributes,
except for a few changes here and there. Since these are attributes, you can set
all of these from the C<< $t_sftp->new() >> method.

    $t_sftp->new(
        host         => 'localhost',
        user         => 'root'
        password     => 'p455w0rdZ'
        debug        => 1     # default: 0
        warn         => 1     # default: 0
        more         => [ qw( -o PreferredAuthentications=password ) ]
        auto_connect => 0     # default: 1
        timeout      => 10    # 10 seconds timeout for the connection
    );

=head2 $t_sftp->host($host)

The host you're connecting to.

=head2 $t_sftp->user($username)

Username you're connecting with.

=head2 $t_sftp->password($password)

Password for the username you're connecting with.

=head2 $t_sftp->debug($boolean)

Debugging flag for I<Net::SFTP>. Haven't used it yet, don't know if it will ever
come in handy.

=head2 $t_sftp->warn($boolean)

Warning flag for I<Net::SFTP>. Haven't used it yet, don't know if it will ever
come in handy.

=head2 $t_sftp->more( [ @args ] )

SSH arguments, such as used in I<Net::SFTP>. These are actually for
I<Net::SSH::Perl>.

=head2 $t_sftp->auto_connect($boolean)

Some methods require a connection which is monitored by an internal attribute
listed below. This method can alter that behavior, dictating that Test::SFTP
should not issue a connection if it's not connected. The default is to issue a
connection if C<< $t_sftp->connected >> returns false.

=head2 $t_sftp->timeout($seconds)

When you want to make sure the login to SFTP won't hang, you can set a timeout.
However, it applies to the login only, and not to any other method.

=head2 Sensitive Attributes

=over 4

=item C<< $t_sftp->connected($boolean) >>

A boolean attribute to note whether the I<Net::SFTP> object is connected.

Most methods used need the object to be connected. This attribute is used
internally to check if it's not connected yet, and if it isn't, it will run the
connect method again in order to connect. This behavior can be altered using the
previous attribute C<< $t_sftp->auto_connect >>.

=item C<< $t_sftp->object($object) >>

This holds the object of I<Net::SFTP>. It's there to allow users more
fingergrain access to the object. With that, you can do:

    is(
        $t_sftp->object->do_read( ... ),
        'Specific test not covered in the framework',
    );

You can change this to a different object you want to use instead of
I<Net::SFTP>, but the API should be as close to it as possible. Goodluck!

=back

=head1 SUBROUTINES/METHODS

=head2 $t_sftp->connect

Test::SFTP does not connect when it's created. You should explicitly connect
using:

    $t_sftp->connect

Then you could use the available testing methods described below.

If the auto_connect attribute (which is set by default) is on, it will connect
as soon as a testing method is used and it finds out it isn't connected already.

=head2 $t_sftp->can_connect($test_name)

Checks whether we were able to connect to the machine. It basically runs the
connect method, but checks if it was successful with a test name.

=head2 $t_sftp->cannot_connect($test_name)

Checks whether we were NOT able to connect to the machine. Runs the connect
method adn checks if it unsuccessful with a test name.

=head2 $t_sftp->is_status( "$number $string" , $test_name )

Checks the status of I<Net::SFTP>. It's the same as
C<< is( "$expected_number $expected_string", Test::SFTP->object->status,
'testing the status returned by Net::SFTP) >>.

This returns the entire string back. It joins both the error number and the
FX2TXT, joined by a space character.

=head2 $t_sftp->is_status_number( $number, $test_name )

Returns the status number, the first part of the whole status.

=head2 $t_sftp->is_status_string( $string, $test_name )

Returns the FX2TXT part of the status.

=head2 $t_sftp->can_get( $filename, $test_name )

Checks whether we're able to get a file.

=head2 $t_sftp->cannot_get( $filename, $test_name )

Checks whether we're unable to get a file.

=head2 $t_sftp->can_put( $filename, $test_name )

Checks whether we're able to upload a file.

=head2 $t_sftp->cannot_put( $filename, $test_name )

Checks whether we're unable to upload a file.

=head2 $t_sftp->can_ls( $filename, $test_name )

Checks whether we're able to ls a folder or file. Can be used to check the
existence of files or folders.

=head2 $t_sftp->cannot_ls( $filename, $test_name )

Checks whether we're unable to ls a folder or file. Can be used to check the
nonexistence of files or folders.

=head1 DEPENDENCIES

L<http://search.cpan.org/perldoc?Moose>

L<http://search.cpan.org/perldoc?Net::SFTP>

L<http://search.cpan.org/perldoc?Test::More>

=head1 AUTHOR

Sawyer X, C<< <xsawyerx at cpan.org> >>

=head1 DIAGNOSTICS

You can use the B<object> attribute to access the I<Net::SFTP> object directly.

=head1 CONFIGURATION AND ENVIRONMENT

Some tests in the module require creating and removing files. As long as we
don't have complete control over the environment we're going to connect to, it's
hard to know if we're gonna upload a file that perhaps already exists already.
We try hard to avoid it by creating a file with a random number as the filename.

So, in previous versions (actually, only 1), these tests were mixed with all the
other tests so if you had set the environment variable to testing, it would test
it with everything. If you don't, it would not test a bunch of other tests that
aren't dangerous at all.

To ask for this to be tested as well, set the environment variable
TEST_SFTP_DANG.

=head1 INCOMPATIBILITIES

This module should be incompatible with taint (-T), because it use I<Net::SFTP>
that utilizes I<Net::SSH::Perl> that does not pass tainted mode.

=head1 BUGS AND LIMITATIONS

This module will have the same limitations that exist for I<Net::SFTP>. Perhaps
more.

Please report any bugs or feature requests to C<bug-test-sftp at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-SFTP>.  I will be
notified, and then you'll automatically be notified of progress on your bug as I
make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::SFTP

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-SFTP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-SFTP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-SFTP>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-SFTP/>

=back


=head1 ACKNOWLEDGEMENTS

Dave Rolsky and David Robins for maintaining I<Net::SFTP>.

=head1 LICENSE AND COPYRIGHT

Copyright 2009 Sawyer X, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

