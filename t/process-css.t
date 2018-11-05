use lib '.';
use t::Helper;

plan skip_all => 'TEST_PROCESS_CSS=1' unless $ENV{TEST_PROCESS_CSS} or $ENV{TEST_ALL};

my $cwd = t::Helper->cwd;
my $t = t::Helper->t(process => ['css', 'js']);

like $t->app->asset('basic.css'), qr{src="/asset/basic\.dev\.css"}, 'asset basic.css';

done_testing;
