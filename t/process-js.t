use lib '.';
use t::Helper;

plan skip_all => 'TEST_PROCESS_JS=1' unless $ENV{TEST_PROCESS_JS};

my $cwd = t::Helper->cwd;
my $t = t::Helper->t(process => ['js']);

like $t->app->asset('foo.js'), qr{src="/asset/foo\.dev\.js"}, 'asset foo.js';

done_testing;
