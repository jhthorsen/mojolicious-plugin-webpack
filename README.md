# NAME

Mojolicious::Plugin::Webpack - Mojolicious ♥ Webpack

# SYNOPSIS

Check out
[https://github.com/jhthorsen/mojolicious-plugin-webpack/tree/master/example](https://github.com/jhthorsen/mojolicious-plugin-webpack/tree/master/example)
for a working example.

## Define assets

One or more assets need to be defined. The minimum is to create one
[entry point](https://webpack.js.org/concepts/#entry) and add it to
the `webpack.custom.js` file.

    # Entrypoint: ./assets/app.js
    // This will result in one css and one js asset.
    import "../css/css-example.css";
    console.log("I'm loaded!");

    # Config file: ./assets/webpack.custom.js
    module.exports = function(config) {
      config.entry = {
        "cool_beans": "./assets/app.js",
      };
    };

## Application

Your lite or full app, need to load [Mojolicious::Plugin::Webpack](https://metacpan.org/pod/Mojolicious::Plugin::Webpack) and
tell it what kind of assets it should be able to process:

    $app->plugin(Webpack => {process => [qw(js css)]});

See ["register"](#register) for more config options.

## Template

To include the generated assets in your template, you can use the ["asset"](#asset)
helper:

    %= asset "myapp.css"
    %= asset "myapp.js"

## Start application

You can start the application using `daemon`, `hypnotoad` or any Mojolicious
server you want, but if you want rapid development you should use
`crushinator`, which is an alternative to `morbo`:

    $ crushinator -h
    $ crushinator ./myapp.pl

However if you want to use another daemon and make `webpack` run, you need to
set the `MOJO_WEBPACK_BUILD` environment variable to "1". Example:

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

[Mojolicious::Plugin::Webpack](https://metacpan.org/pod/Mojolicious::Plugin::Webpack) is a [Mojolicious](https://metacpan.org/pod/Mojolicious) plugin to make it easier to
work with [https://webpack.js.org/](https://webpack.js.org/). This means that this is mostly a
developer tool. This point is emphasized by installing a "shim" so your
application does not depend on this plugin at all when running in production.
See ["PLUGIN SHIM" in Mojolicious::Plugin::Webpack::Builder](https://metacpan.org/pod/Mojolicious::Plugin::Webpack::Builder#PLUGIN-SHIM) for more information.

Note that [Mojolicious::Plugin::Webpack](https://metacpan.org/pod/Mojolicious::Plugin::Webpack) is currently EXPERIMENTAL, and
changes might come without a warning.

# MIGRATING FROM ASSETPACK

Are you already a user of [Mojolicious::Plugin::AssetPack](https://metacpan.org/pod/Mojolicious::Plugin::AssetPack)?
[Mojolicious::Plugin::Webpack](https://metacpan.org/pod/Mojolicious::Plugin::Webpack) will automatically detect your `assetpack.def`
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
HTML tag created with either ["javascript" in Mojolicious::Plugin::TagHelpers](https://metacpan.org/pod/Mojolicious::Plugin::TagHelpers#javascript) or
["stylesheet" in Mojolicious::Plugin::TagHelpers](https://metacpan.org/pod/Mojolicious::Plugin::TagHelpers#stylesheet) if a valid asset name is passed
in.

You can also use it to call a method and pass on `$c` by passing in a method
name as the first argument, such as ["url\_for"](#url_for).

# ATTRIBUTES

## assets\_dir

    $path = $self->assets_dir;

Holds a [Mojo::File](https://metacpan.org/pod/Mojo::File) object pointing to the private directoy where source
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

Holds a [Mojo::File](https://metacpan.org/pod/Mojo::File) object pointing to the public directoy where processed
assets are written to. Default value is:

    $app->static->paths->[0] . "/asset";

## route

    $route = $self->route;

Holds a [Mojolicious::Routes::Route](https://metacpan.org/pod/Mojolicious::Routes::Route) object that generates the URLs to a
processed asset. Default value is `/asset/*name`.

# METHODS

## register

    $self->register($app, \%config);
    $app->plugin("Webpack", \%config);

Used to register this plugin into your [Mojolicious](https://metacpan.org/pod/Mojolicious) app.

The `%config` passed when loading this plugin can have any of the
["ATTRIBUTES" in Mojolicious::Plugin::Webpack::Builder](https://metacpan.org/pod/Mojolicious::Plugin::Webpack::Builder#ATTRIBUTES), in addition to these
attributes:

- helper

    Name of the helper that will be added to your application.

    Default: "asset".

## url\_for

    $url = $self->url_for($c, $asset_name);

Returns a [Mojo::URL](https://metacpan.org/pod/Mojo::URL) for a given asset.

# AUTHOR

Jan Henning Thorsen

# COPYRIGHT AND LICENSE

Copyright (C) 2018, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

# SEE ALSO

[Mojolicious::Plugin::Webpack::Builder](https://metacpan.org/pod/Mojolicious::Plugin::Webpack::Builder).

[Mojolicious::Plugin::AssetPack](https://metacpan.org/pod/Mojolicious::Plugin::AssetPack).
