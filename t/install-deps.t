use Mojo::Base -strict;
use Mojo::File 'path';
use Test::Mojo;
use Test::More;

plan skip_all => 'TEST_NODE_INSTALL=1' unless $ENV{TEST_NODE_INSTALL};

my $olddir = path;
my $workdir = path(path(__FILE__)->dirname, 'install-deps');
mkdir $workdir;
plan skip_all => "$workdir does not exist" unless -d $workdir;
chdir $workdir or die "chdir $workdir: $!";
$workdir = path;

$ENV{MOJO_WEBPACK_ARGS} = '';
use Mojolicious::Lite;
plugin Webpack => {dependencies => {core => ['underscore'], js => []}};

my $t     = Test::Mojo->new;
my $asset = $t->app->asset;

is $asset->_generate($t->app, $workdir, 'package.json'), 'generated', 'generated package.json';

$asset->dependencies->{core} = ['underscore'];
$asset->dependencies->{js}   = [];
is $asset->_install_node_deps($workdir), 1, 'first run';
is $asset->_install_node_deps($workdir), 0, 'second run';

plugin Webpack => {process => [qw(js css)], dependencies => {core => ['underscore'], js => []}};
$asset = $t->app->asset;

$asset->{process} = [qw(js css)];
is $asset->_install_node_deps($workdir), 3, 'more deps for css';
is $asset->_install_node_deps($workdir), 0, 'all done';

done_testing;

END {
  chdir $olddir if $olddir;
  $workdir->remove_tree if $workdir;
}
