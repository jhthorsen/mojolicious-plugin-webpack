use lib '.';
use t::Helper;

my $cwd = t::Helper->cwd;
my $t   = t::Helper->t(args => '');
my $c   = $t->app->build_controller;

is $c->asset('foo.js'), '<script src="/asset/foo.1234567890.js" type="text/javascript"></script>', 'asset foo.js';

eval { $c->asset('bar.js') };
like $@, qr{Invalid asset name bar\.js}, 'asset bar.js';

done_testing;
