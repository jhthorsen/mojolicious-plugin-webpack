# NAME

Mojolicious::Plugin::Webpack - Mojolicious ♥ Webpack

# SYNOPSIS

## Define entrypoint

Create a file "./assets/index.js" relative to you application directory with
the following content:

    console.log('Cool beans!');

## Application

Your [Mojolicious](https://metacpan.org/pod/Mojolicious) application need to load the
[Mojolicious::Plugin::Webpack](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AWebpack) plugin and tell it what kind of assets it
should be able to process:

    $app->plugin(Webpack => {process => [qw(js css)]});

See ["register"](#register) for more configuration options.

## Template

To include the generated assets in your template, you can use the ["asset"](#asset)
helper:

    %= asset "cool_beans.css"
    %= asset "cool_beans.js"

## Run the application

You can start the application using `daemon`, `hypnotoad` or any Mojolicious
server you want, but if you want rapid development you should use
`mojo webpack`, which is an alternative to `morbo`:

    $ mojo webpack -h
    $ mojo webpack ./script/myapp.pl

However if you want to use another daemon and force `webpack` to run, you need
to set the `MOJO_WEBPACK_BUILD` environment variable to "1". Example:

    MOJO_WEBPACK_BUILD=1 ./script/myapp.pl daemon

## Testing

If you want to make sure you have built all the assets, you can make a test
file like "build-assets.t":

    use Test::More;
    use Test::Mojo;

    # Run with TEST_BUILD_ASSETS=1 prove -vl t/build-assets.t
    plan skip_all => "TEST_BUILD_ASSETS=1" unless $ENV{TEST_BUILD_ASSETS};

    # Load the app and make a test object
    $ENV{MOJO_MODE}          = 'production';
    $ENV{MOJO_WEBPACK_BUILD} = 1;
    use FindBin;
    require "$FindBin::Bin/../script/myapp.pl";
    my $t = Test::Mojo->new;

    # Find all the tags and make sure they can be loaded
    $t->get_ok("/")->status_is(200);
    $t->element_count_is('script[src], link[href][rel=stylesheet]', 2);
    $t->tx->res->dom->find("script[src], link[href][rel=stylesheet]")->each(sub {
      $t->get_ok($_->{href} || $_->{src})->status_is(200);
    });

    done_testing;

# DESCRIPTION

[Mojolicious::Plugin::Webpack](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AWebpack) is a [Mojolicious](https://metacpan.org/pod/Mojolicious) plugin to make it easier to
work with [https://webpack.js.org/](https://webpack.js.org/) or [https://rollupjs.org/](https://rollupjs.org/). This plugin
will...

1. Generate a minimal `package.json` and a Webpack or Rollup config file. Doing
this manually is possible, but it can be quite time consuming to figure out all
the bits and pieces if you are not already familiar with Webpack.
2. Load the entrypoint "./assets/index.js", which is the starting point of your
client side application. The entry file can load JavaScript, CSS, SASS, ... as
long as the appropriate processing plugin is loaded.
3. It can be difficult to know exactly which plugins to use with Webpack. Because
of this [Mojolicious::Plugin::Webpack](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AWebpack) has some predefined rules for which
Nodejs dependencies to fetch and  install. None of the nodejs modules are
required in production though, so it will only be installed while developing.
4. While developing, the webpack executable will be started automatically next to
[Mojo::Server::Morbo](https://metacpan.org/pod/Mojo%3A%3AServer%3A%3AMorbo). Webpack will be started with the appropriate switches
to watch your source files and re-compile on change.

## Rollup

[rollup.js](https://rollupjs.org/) is an alternative to Webpack. Both
accomplish more or less the same thing, but in different ways.

To be able to use rollup, you have to load this plugin with a different engine:

    $app->plugin(Webpack => {engine => 'Mojo::Alien::rollup', process => [qw(js css)]});

## Notice

[Mojolicious::Plugin::Webpack](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AWebpack) is currently EXPERIMENTAL.

# HELPERS

## asset

    # Call a method or access an attribute in this class
    my $path = $app->asset->engine->out_dir;

    # Call a method, but from inside a mojo template
    %= asset->url_for($c, "cool_beans.css")

    # Generate a HTML tag
    my $bytestream = $c->asset("cool_beans.js", @args);

    # Generate a HTML tag, but from inside a mojo template
    %= asset "cool_beans.css", media => "print"
    %= asset(url_for => "cool_beans.css")

The most basic usage of this helper is to create a HTML tag using
["javascript" in Mojolicious::Plugin::TagHelpers](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3ATagHelpers#javascript) or
["stylesheet" in Mojolicious::Plugin::TagHelpers](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3ATagHelpers#stylesheet) if a valid asset name is passed in.

On the other hand, the helper will return the plugin instance if no arguments
are passed in, allowing you to call any of the ["METHODS"](#methods) or access the
["ATTRIBUTES"](#attributes).

# HOOKS

## before\_webpack\_start

    $app->before_webpack_start(sub { my $webpack = shift; ... });

Emitted right before the plugin starts building or loading in the generated
assets. Useful if you want to change any of the ["engine"](#engine) attributes from the
defaults.

# ATTRIBUTES

## engine

    $engine = $webpack->engine;

Returns a [Mojo::Alien::webpack](https://metacpan.org/pod/Mojo%3A%3AAlien%3A%3Awebpack) or [Mojo::Alien::rollup](https://metacpan.org/pod/Mojo%3A%3AAlien%3A%3Arollup) object.

# METHODS

## asset\_map

    $hash_ref = $webpack->asset_map;

Reads all the generated files in ["asset\_path"](#asset_path) and returns a hash-ref like
this:

    {
      "relative/output.js" => {               # Key is a friendly name, withouc checksum
        ext      => 'css',                    # File extension
        helper   => 'javascript',             # Mojolicious helper used to render the asset
        rel_name => "relatibe/output.xyz.js", # Relative filename with checksum
      },
      ...
    }

Note that changing this hash might change how ["asset"](#asset) and ["url\_for"](#url_for) behaves!

## register

    $webpack->register($app, \%config);
    $app->plugin("Webpack", \%config);

Used to register this plugin into your [Mojolicious](https://metacpan.org/pod/Mojolicious) app.

The `%config` passed when loading this plugin can have any of these
attributes:

- asset\_path

    Can be used to specify an alternative static directory to output the built
    assets to.

    Default: "/asset".

- cache\_control

    Used to set the response "Cache-Control" header for built assets.

    Default: "no-cache" while developing and "max-age=86400" in production.

- engine

    Must be a valid engine class name. Examples:

        $app->plugin("Webpack", {engine => 'Mojo::Alien::rollup'});
        $app->plugin("Webpack", {engine => 'Mojo::Alien::webpack'});

    Default: [Mojo::Alien::webpack](https://metacpan.org/pod/Mojo%3A%3AAlien%3A%3Awebpack).

- helper

    Name of the helper that will be added to your application.

    Default: "asset".

- process

    Used to specify ["include" in Mojo::Alien::webpack](https://metacpan.org/pod/Mojo%3A%3AAlien%3A%3Awebpack#include) or  ["include" in Mojo::Alien::rollup](https://metacpan.org/pod/Mojo%3A%3AAlien%3A%3Arollup#include).

    Default: `['js']`.

## url\_for

    $url = $webpack->url_for($c, $asset_name);

Returns a [Mojo::URL](https://metacpan.org/pod/Mojo%3A%3AURL) for a given asset.

# AUTHOR

Jan Henning Thorsen

# COPYRIGHT AND LICENSE

Copyright (C) Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

# SEE ALSO

[Mojo::Alien::rollup](https://metacpan.org/pod/Mojo%3A%3AAlien%3A%3Arollup), [Mojo::Alien::webpack](https://metacpan.org/pod/Mojo%3A%3AAlien%3A%3Awebpack).
