use lib '.';
use t::Helper;

plan skip_all => 'TEST_PROCESS_SASS=1' unless $ENV{TEST_PROCESS_SASS} or $ENV{TEST_ALL};

my $cwd = t::Helper->cwd;
my $t = t::Helper->t(process => ['js', 'sass']);

like $t->app->asset('basic.css'), qr{src="/asset/basic\.dev\.css"}, 'asset basic.css';

done_testing;
