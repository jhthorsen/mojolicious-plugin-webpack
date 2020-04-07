#!/usr/bin/env perl
use Mojolicious::Lite;
use Mojo::File 'curfile';
require lib;

$ENV{MOJO_WEBPACK_CONFIG} = "@{[curfile->sibling('rollup.config.js')]}";

my $lib_path = "@{[curfile->dirname->dirname->sibling('lib')]}";
lib->import($lib_path);

plugin Webpack => {
  process => ['svelte'],
  dependencies =>
    {core => 'rollup', svelte => [qw(rollup-plugin-svelte svelte)]}
};
get '/' => 'index';

{
  local $ENV{PERL5OPT} = "-I$lib_path";
  app->start;
}

__DATA__
@@ index.html.ep
<!DOCTYPE html>
<html>
  <head>
    <title>Mojolicious ♥ Webpack</title>
    % # asset 'example.css'
  </head>
  <body>
    <h1>Mojolicious ♥ Rollup</h1>
    <p>
      This is a demo for using <a href="https://rollupjs.org/">Rollup</a>
      together with <a href="https://mojolicious.org/">Mojolicious</a>.
    </p>

    <pre># Create a rollup config file
# See https://github.com/jhthorsen/mojolicious-plugin-webpack/tree/master/example/rollup
# for example config file.
$ $EDITOR rollup.config.js

# Replace default webpack with rollup instead by loading a config file containing "rollup".
$ perl lite.pl webpack -c ./rollup.config.js</pre>

    <h2>The generated application</h2>
    %= asset 'example.js'
  </body>
</html>
