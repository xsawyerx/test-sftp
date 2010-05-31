use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test::SFTP',
    license             => 'perl',
    dist_author         => q{Sawyer X <xsawyerx@cpan.org>},
    dist_version_from   => 'lib/Test/SFTP.pm',
    build_requires => {
        'Test::More' => 0,
        'IO::Prompt' => '0.99.4',
        'English'    => 1.02,
    },

    requires => {
        'Carp'                 => 0,
        'perl'                 => 5.006,
        'parent'               => 0,
        'Test::More'           => 0.78,
        'Moose'                => 0.63,
        'Net::SFTP'            => 0.10,
        'namespace::autoclean' => 0,
    },

    add_to_cleanup      => [ 'Test-SFTP-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
