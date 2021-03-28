use Mojo::Base -strict;
use Mojo::Alien::rollup;
use Mojo::File qw(path);
use Mojo::JSON::Pointer;
use Test::More;

plan skip_all => 'TEST_ROLLUP=1' unless $ENV{TEST_ROLLUP} or $ENV{TEST_ALL};

my $remove_tree = $ENV{TEST_CONTINUE} ? sub { } : 'remove_tree';
chdir(my $work_dir = path(local => path($0)->basename)->tap($remove_tree)->make_path) or die $!;

my $rollup = Mojo::Alien::rollup->new;
$rollup->include([qw(js css images)]);
$rollup->dependencies->{images} = [qw(rollup-plugin-img)];

subtest build => sub {
  ok make_project_files(), 'created assets';
  is $rollup->build, $rollup, 'build';
};

subtest asset_map => sub {
  my $assets = $rollup->asset_map;

  my %generated = (
    'alien-rollup-files-t.css'   => 0,
    'alien-rollup-files-t.js'    => 0,
    'images/1x1-red.png'         => 0,
    'images/1x1-transparent.png' => 0,
  );

  for my $rel (sort keys %$assets) {
    ok -e $assets->{$rel}{path}, $rel;
    ok $assets->{$rel}{ext}, 'ext';
    defined $generated{$_} && $generated{$_}++ for @{$assets->{$rel}{aliases}};
  }

  is_deeply [values %generated], [1, 1, 1, 1], 'generated output assets';
};

done_testing;

sub make_project_files {
  my $data = Mojo::Loader::data_section('main');
  for my $name (keys %$data) {
    my $file = $rollup->assets_dir->child(split '/', $name);
    $file->dirname->make_path;
    $file->spurt($data->{$name});
  }

  return $data;
}

__DATA__
@@ app.js
const app = {
  start: () => console.log('Starting!'),
};

export default app;
@@ css/cool-stuff.css
body {
  background: #fefefe;
}
@@ index.js
import './css/cool-stuff.css';
import './images/1x1-red.png';
import './images/1x1-transparent.png';
import app from './app.js';
app.start();
@@ images/1x1-red.png (base64)
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQImWP4z8DwHwAFAAH/q842iQAAAABJRU5ErkJggg==
@@ images/1x1-transparent.png (base64)
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQImWNgYGBgAAAABQABh6FO1AAAAABJRU5ErkJggg
@@ rollup.config.d/images.js
const image = require('rollup-plugin-img');
module.exports = function(config) {
  config.plugins.push(image({hash: true, limit: 1, output: 'dist/images'}));
};
