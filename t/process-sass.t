use lib '.';
use t::Helper;

# https://github.com/jhthorsen/mojolicious-plugin-webpack/runs/1586324146?check_suite_focus=true
plan skip_all => 'GITHUB_WORKFLOW' if $ENV{GITHUB_WORKFLOW};

plan skip_all => 'TEST_PROCESS_SASS=1' unless $ENV{TEST_PROCESS_SASS} or $ENV{TEST_ALL};

$ENV{MOJO_WEBPACK_BUILD} //= 1;
my $cwd = t::Helper->cwd;
my $t   = t::Helper->t(process => ['js', 'sass']);

like $t->app->asset('basic.css'), qr{href="/asset/basic\.development\.css"}, 'asset basic.css';
$t->get_ok('/asset/basic.development.css')->status_is(200)->content_like(qr{content:\s*"basic\.scss"});

done_testing;
