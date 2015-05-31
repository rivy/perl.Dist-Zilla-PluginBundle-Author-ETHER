use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Path::Tiny;

use lib 't/lib';
use Helper;
use NoNetworkHits;
use NoPrereqChecks;

use Dist::Zilla::Plugin::MakeMaker;
plan skip_all => 'need recent [MakeMaker] to test use of default_jobs option'
    if not Dist::Zilla::Plugin::MakeMaker->can('default_jobs');

use Test::File::ShareDir -share => { -dist => { 'Dist-Zilla-PluginBundle-Author-ETHER' => 'share' } };

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                'GatherDir',
                [ '@Author::ETHER' => {
                    '-remove' => \@REMOVED_PLUGINS,
                    server => 'none',
                    installer => 'MakeMaker',
                    'MakeMaker.default_jobs' => '8',
                    'RewriteVersion::Transitional.skip_version_provider' => 1,
                    'Test::MinimumVersion.max_target_perl' => '5.010',
                } ],
            ),
            path(qw(source lib DZT Sample.pm)) => "package DZT::Sample;\n\n1",
        },
    },
);

assert_no_git($tzil);

$tzil->chrome->logger->set_debug(1);
is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
);

is(
    $tzil->plugin_named('@Author::ETHER/MakeMaker')->default_jobs,
    8,
    'extra arg added to plugin was overridden by the user',
);

is(
    $tzil->plugin_named('@Author::ETHER/Test::MinimumVersion')->max_target_perl,
    '5.010',
    'max_target_perl option overrides default',
);

# check that everything we loaded is in the pluginbundle's run-requires
all_plugins_in_prereqs($tzil,
    exempt => [ 'Dist::Zilla::Plugin::GatherDir' ],     # used by us here
    additional => [
        'Dist::Zilla::Plugin::MakeMaker::Fallback',     # via default installer option
        'Dist::Zilla::Plugin::ModuleBuildTiny::Fallback', # ""
    ],
);

done_testing;
