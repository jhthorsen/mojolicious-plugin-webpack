# NAME

Mojolicious::Plugin::Webpack - Mojolicious ♥ Webpack

# SYNOPSIS

Check out
[https://github.com/jhthorsen/mojolicious-plugin-webpack/tree/master/example/webpack](https://github.com/jhthorsen/mojolicious-plugin-webpack/tree/master/example/webpack)
for a working example.

## Define assets

One or more assets need to be defined. The minimum is to create one
[entry point](https://webpack.js.org/concepts/#entry) and add it to
the `webpack.custom.js` file.

    # Entrypoint: ./assets/entry-cool_beans.js
    // This will result in one css and one js asset.
    import '../css/css-example.css';
    console.log('I'm loaded!');

    # Config file: ./assets/webpack.custom.js
    module.exports = function(config) {
      config.entry = {
        'cool_beans': './assets/entry-cool_beans.js',
      };
    };

## Application

Your lite or full app, need to load [Mojolicious::Plugin::Webpack](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AWebpack) and
tell it what kind of assets it should be able to process:

    $app->plugin(Webpack => {process => [qw(js css)]});

See ["register"](#register) for more config options.

## Template

To include the generated assets in your template, you can use the ["asset"](#asset)
helper:

    %= asset "cool_beans.css"
    %= asset "cool_beans.js"

## Start application

You can start the application using `daemon`, `hypnotoad` or any Mojolicious
server you want, but if you want rapid development you should use
`mojo webpack`, which is an alternative to `morbo`:

    $ mojo webpack -h
    $ mojo webpack ./myapp.pl

However if you want to use another daemon and force `webpack` to run, you need
to set the `MOJO_WEBPACK_BUILD` environment variable to "1". Example:

    MOJO_WEBPACK_BUILD=1 ./myapp.pl daemon

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
    require "$FindBin::Bin/../myapp.pl";
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
work with [https://webpack.js.org/](https://webpack.js.org/). This plugin will...

1. Generate a minimal `package.json` and a Webpack config file. Doing this
manually is possible, but it can be quite time consuming to figure out all the
bits and pieces if you are not already familiar with Webpack.

        ./package.json
        ./webpack.config.js

2. Generate a `webpack.custom.js` which is meant to be the end user config file
where you can override any part of the default config. You are free to modify
`webpack.config.js` directly, but doing so will prevent
[Mojolicious::Plugin::Webpack](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AWebpack) from patching it in the future.

    The default `webpack.custom.js` file will simply define an "entry" which is
    the starting point of your application.

        ./assets/webpack.custom.js

3. Generate an entry file, which is the starting point of your client side
application. The entry file can load JavaScript, CSS, SASS, ... as long as the
appropriate processing plugin is loaded by Webpack.

        ./assets/my_app.js

4. It can be difficult to know exactly which plugins to use with Webpack. Because
of this, [Mojolicious::Plugin::Webpack](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AWebpack) has some predefined rules for which
Nodejs dependencies to fetch and  install. None of the nodejs modules are
required in production though, so it will only be installed while developing.
5. While developing, the webpack executable will be started automatically next to
[Mojo::Server::Morbo](https://metacpan.org/pod/Mojo%3A%3AServer%3A%3AMorbo). Webpack will be started with the appropriate switches
to watch your source files and re-compile on change.

There is also support for [https://rollupjs.org/](https://rollupjs.org/). See ["Rollup"](#rollup) for more
information.

[Mojolicious::Plugin::Webpack](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AWebpack) is currently EXPERIMENTAL, but it's unlikely it
will change dramatically.

After creating the file, you can run the command below to get a development
server:

    $ perl myapp.pl webpack -c rollup.config.js

If you want to do ["Testing"](#testing), you have to set the environment variable
`MOJO_WEBPACK_CONFIG` in addition to [TEST\_BUILD\_ASSETS](https://metacpan.org/pod/TEST_BUILD_ASSETS):

    $ENV{MOJO_WEBPACK_CONFIG} = 'rollup.config.js';

## Rollup

[rollup.js](https://rollupjs.org/) is an alternative to Webpack. Both
accomplish more or less the same thing, but in different ways. There might be a
"Rollup" plugin in the future, but for now this plugin supports both.

For now, you need to write your own "rollup.config.js" file. See
[https://github.com/jhthorsen/mojolicious-plugin-webpack/tree/master/example/rollup](https://github.com/jhthorsen/mojolicious-plugin-webpack/tree/master/example/rollup)
for a working example.

# MIGRATING FROM ASSETPACK

Are you already a user of [Mojolicious::Plugin::AssetPack](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AAssetPack)?
[Mojolicious::Plugin::Webpack](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AWebpack) will automatically detect your `assetpack.def`
file and convert it into a custom webpack config, so you don't have to do
much, except changing how you load the plugin:

    # AssetPack
    $app->plugin(AssetPack => {pipes => [qw(Sass JavaScript)]});

    # Webpack
    $app->plugin(Webpack => {process => [qw(sass js)]});

# HELPERS

## asset

    # Call a method or access an attribute in this class
    my $path = $app->asset->out_dir;

    # Call a method, but from inside a mojo template
    %= asset->url_for($c, "cool_beans.css")

    # Generate a HTML tag
    my $bytestream = $c->asset("cool_beans.js", @args);

    # Generate a HTML tag, but from inside a mojo template
    %= asset "cool_beans.css", media => "print"
    %= asset(url_for => "cool_beans.css")

This helper will return the plugin instance if no arguments is passed in, or a
HTML tag created with either ["javascript" in Mojolicious::Plugin::TagHelpers](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3ATagHelpers#javascript) or
["stylesheet" in Mojolicious::Plugin::TagHelpers](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3ATagHelpers#stylesheet) if a valid asset name is passed
in.

You can also use it to call a method and pass on `$c` by passing in a method
name as the first argument, such as ["url\_for"](#url_for).

# ATTRIBUTES

## assets\_dir

    $path = $self->assets_dir;

Holds a [Mojo::File](https://metacpan.org/pod/Mojo%3A%3AFile) object pointing to the private directoy where source
files are read from. Defaults value is:

    $app->home->rel_file("assets");

## node\_env

    $str = $self->node_env;

Used to set `NODE_ENV` environment value.

Defaults value is "development" if ["mode" in Mojolicious](https://metacpan.org/pod/Mojolicious#mode) is "development" and
"production" otherwise. This value usually tells webpack to either minify the
assets or generate readable output while developing.

## out\_dir

    $path = $self->out_dir;

Holds a [Mojo::File](https://metacpan.org/pod/Mojo%3A%3AFile) object pointing to the public directoy where processed
assets are written to. Default value is:

    $app->static->paths->[0] . "/asset";

## route

    $route = $self->route;

Holds a [Mojolicious::Routes::Route](https://metacpan.org/pod/Mojolicious%3A%3ARoutes%3A%3ARoute) object that generates the URLs to a
processed asset. Default value is `/asset/*name`.

# METHODS

## register

    $self->register($app, \%config);
    $app->plugin("Webpack", \%config);

Used to register this plugin into your [Mojolicious](https://metacpan.org/pod/Mojolicious) app.

The `%config` passed when loading this plugin can have any of the
["ATTRIBUTES" in Mojolicious::Plugin::Webpack::Builder](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AWebpack%3A%3ABuilder#ATTRIBUTES), in addition to these
attributes:

- helper

    Name of the helper that will be added to your application.

    Default: "asset".

## url\_for

    $url = $self->url_for($c, $asset_name);

Returns a [Mojo::URL](https://metacpan.org/pod/Mojo%3A%3AURL) for a given asset.

# AUTHOR

Jan Henning Thorsen

# COPYRIGHT AND LICENSE

Copyright (C) 2018, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

# SEE ALSO

[Mojolicious::Plugin::Webpack::Builder](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AWebpack%3A%3ABuilder).

[Mojolicious::Plugin::AssetPack](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AAssetPack).
