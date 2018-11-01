#!/usr/bin/env perl
use Mojolicious::Lite;

use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

plugin 'Webpack';
get '/' => 'index';
app->start;

__DATA__
@@ index.html.ep
<!DOCTYPE html>
<html>
  <head>
    <title>Mojolicious ♥ Webpack</title>
    <link rel="stylesheet" href="/asset/cool_app.dev.css">
    <script src="/asset/cool_app.dev.js"></script>
    %= asset 'demo.css'
  </head>
  <body>
    <h1>Mojolicious ♥ Webpack</h1>
    <p>
      This is a demo for using <a href="https://webpack.js.org/">Webpack</a>
      together with <a href="https://mojolicious.org/">Mojolicious</a>.
    </p>
  </body>
</html>
