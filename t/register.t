use lib '.';
use t::Helper;

my $t = t::Helper->t(args => '');
my $asset = $t->app->asset;
is $asset->env,          'development',         'env';
is $asset->daemon,       undef,                 'daemon';
like $asset->assets_dir, qr{\bassets$},         'assets_dir';
like $asset->out_dir,    qr{\bpublic\W+asset$}, 'out_dir';
is_deeply + [sort keys %{$asset->dependencies}], [qw(core css js sass vue)], 'dependencies';
is_deeply $asset->process, ['js'], 'process';

my $env = $asset->_environment_variables;
is $env->{NODE_ENV},             'development',                            'NODE_ENV';
is $env->{WEBPACK_RULE_FOR_JS},  1,                                        'WEBPACK_RULE_FOR_JS';
is $env->{WEBPACK_SOURCE_MAPS},  1,                                        'WEBPACK_SOURCE_MAPS';
like $env->{WEBPACK_ASSETS_DIR}, qr{\bassets\W*$},                         'WEBPACK_ASSETS_DIR';
like $env->{WEBPACK_OUT_DIR},    qr{\bpublic\W+asset\W*$},                 'WEBPACK_OUT_DIR';
like $env->{WEBPACK_SHARE_DIR},  qr{\bMojolicious\W+Plugin\W+Webpack\W*$}, 'WEBPACK_SHARE_DIR';
ok !$env->{WEBPACK_RULE_FOR_CSS}, 'WEBPACK_RULE_FOR_CSS';

# TODO: Not sure if these variables should be documented or not
$ENV{WEBPACK_SHARE_DIR}    = '/what/ever';
$ENV{WEBPACK_AUTO_CLEANUP} = '0';
$ENV{WEBPACK_SOURCE_MAPS}  = '0';
$env = t::Helper->t(args => '')->app->asset->_environment_variables;
is $env->{WEBPACK_AUTO_CLEANUP}, 0,            'WEBPACK_AUTO_CLEANUP';
is $env->{WEBPACK_SOURCE_MAPS},  0,            'WEBPACK_SOURCE_MAPS';
is $env->{WEBPACK_SHARE_DIR},    '/what/ever', 'WEBPACK_SHARE_DIR';

done_testing;