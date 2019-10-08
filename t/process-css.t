use lib '.';
use t::Helper;

plan skip_all => 'TEST_PROCESS_CSS=1' unless $ENV{TEST_PROCESS_CSS} or $ENV{TEST_ALL};

$ENV{MOJO_WEBPACK_BUILD} //= 1;
my $cwd = t::Helper->cwd;
my $t   = t::Helper->t(process => ['css', 'js']);

like $t->app->asset('basic.css'), qr{href="/asset/basic\.development\.css"}, 'asset basic.css';
$t->get_ok('/asset/basic.development.css')->status_is(200)->content_like(qr{content:\s*"basic\.css"});

done_testing;
