use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

$ENV{MOJO_WEBPACK_ARGS} = '';

use Mojolicious::Lite;
plugin 'Webpack';

my $t = Test::Mojo->new;
is $t->app->asset->daemon,       undef,                 'daemon';
like $t->app->asset->assets_dir, qr{\bassets$},         'assets_dir';
like $t->app->asset->out_dir,    qr{\bpublic\W+asset$}, 'out_dir';
is_deeply + [sort keys %{$t->app->asset->dependencies}], [qw(core css js sass vue)], 'dependencies';
is_deeply $t->app->asset->process, ['js'], 'process';

done_testing;
