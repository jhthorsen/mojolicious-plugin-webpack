package Mojolicious::Plugin::Webpack;
use Mojo::Base 'Mojolicious::Plugin';

use Carp 'confess';
use Mojo::File 'path';
use Mojo::JSON;
use Mojo::Path;

use constant LAZY => $ENV{MOJO_WEBPACK_LAZY} ? 1 : 0;

our $VERSION = '0.02';

sub assets_dir { shift->{assets_dir} }

has dependencies => sub {
  return {
    core => [qw(webpack-cli webpack webpack-md5-hash html-webpack-plugin)],
    css  => [qw(css-loader mini-css-extract-plugin optimize-css-assets-webpack-plugin)],
    js   => [qw(@babel/core @babel/preset-env babel-loader uglifyjs-webpack-plugin)],
    sass => [qw(node-sass sass-loader)],
    vue  => [qw(vue vue-loader vue-template-compiler)],
  };
};

sub out_dir { shift->{out_dir} }
sub route   { shift->{route} }

sub register {
  my ($self, $app, $config) = @_;
  my $helper = $config->{helper} || 'asset';

  # TODO: Not sure if this should be global or not
  $ENV{NODE_ENV} ||= $app->mode eq 'development' ? 'development' : 'production';

  $self->{$_} = $config->{$_} // 1 for qw(auto_cleanup source_maps);
  $self->{process} = $config->{process} || ['js'];
  $self->{route} ||= $app->routes->route('/asset/*name')->via(qw(HEAD GET))->name('webpack.asset');

  $self->{$_} = path $config->{$_} for grep { $config->{$_} } qw(assets_dir out_dir);
  $self->{assets_dir} ||= path $app->home->rel_file('assets');
  $self->{out_dir} ||= $self->_build_out_dir($app);

  $self->dependencies->{$_} = $config->{dependencies}{$_} for keys %{$config->{dependencies} || {}};
  $self->_webpack_run($app) if $ENV{MOJO_WEBPACK_ARGS} // 1;
  $app->helper($helper => sub { $self->_helper(@_) });
}

sub _build_out_dir {
  my ($self, $app) = @_;
  my $path = Mojo::Path->new($self->route->render({name => 'name.ext'}));
  pop @$path;
  return path $app->static->paths->[0], @$path;
}

sub _helper {
  my ($self, $c, $name, @args) = @_;
  return $self if @_ == 2;

  $self->_register_assets if !$self->{assets} or LAZY;    # Lazy read the generated markup
  my $asset = $self->{assets}{$name} or confess qq(Unknown asset name "$name".);
  my ($tag_helper, $route_args) = @$asset;
  return $c->$tag_helper($c->url_for('webpack.asset', $route_args), @args);
}

sub _install_node_deps {
  my $self         = shift;
  my $package_file = $self->{files}{'package.json'}[1];
  my $package_json = Mojo::JSON::decode_json($package_file->slurp);
  my $n            = 0;

  my $CWD = Mojolicious::Plugin::Webpack::CWD->new($package_file->dirname);
  system qw(npm install) if %{$package_json->{dependencies}} and !-d 'node_modules';

  for my $preset ('core', @{$self->{process}}) {
    for my $module (@{$self->dependencies->{$preset} || []}) {
      next if $package_json->{dependencies}{$module};
      warn "[Webpack] npm install $module\n" if $ENV{MOJO_WEBPACK_DEBUG};
      system npm => install => $module;
      $n++;
    }
  }

  return $n;
}

sub _render_to_file {
  my ($self, $app, $name, $out_file) = @_;
  my $is_generated = '';

  eval {
    $out_file ||= $app->home->rel_file($name);
    my $CFG = $out_file->open('<');
    /Autogenerated\s*by\s*Mojolicious-Plugin-Webpack/i and $is_generated = $_ while <$CFG>;
  };

  return $self->{files}{$name} = [custom => $out_file] if !$is_generated and -r $out_file;
  return $self->{files}{$name} = [current => $out_file] if $is_generated =~ /\b$VERSION\b/;

  my $template = $self->_share_dir->child($name)->slurp;
  $template =~ s!__AUTOGENERATED__!Autogenerated by Mojolicious-Plugin-Webpack $VERSION!g;
  $template =~ s!__NAME__!{$app->moniker}!ge;
  $template =~ s!__VERSION__!{$app->VERSION || '0.0.1'}!ge;
  $out_file->spurt($template);
  return $self->{files}{$name} = [generated => $out_file];
}

sub _register_assets {
  my $self           = shift;
  my $path_to_markup = $self->out_dir->child(sprintf 'webpack.%s.html',
    $ENV{WEBPACK_CUSTOM_NAME} || ($ENV{NODE_ENV} ne 'production' ? 'development' : 'production'));
  my $markup  = Mojo::DOM->new($path_to_markup->slurp);
  my $name_re = qr{(.*)\.\w+\.(css|js)$}i;

  $markup->find('link')->each(sub {
    my $name = shift->{href} // '';
    $self->{assets}{"$1.$2"} = [stylesheet => {name => $name}] if $name =~ $name_re;
  });

  $markup->find('script')->each(sub {
    my $name = shift->{src} // '';
    $self->{assets}{"$1.$2"} = [javascript => {name => $name}] if $name =~ $name_re;
  });
}

sub _webpack_run {
  my ($self, $app) = @_;

  $self->_render_to_file($app, 'package.json');
  $self->_render_to_file($app, 'webpack.config.js');
  $self->_render_to_file($app, 'webpack.custom.js',
    $self->assets_dir->child(sprintf 'webpack.%s.js', $ENV{WEBPACK_CUSTOM_NAME} || 'custom'));
  $self->_install_node_deps;

  my $env = $self->_webpack_environment;
  map { warn "[Webpack] $_=$env->{$_}\n" } grep {/^WEBPACK_/} sort keys %$env if $ENV{MOJO_WEBPACK_DEBUG};

  path($env->{WEBPACK_OUT_DIR})->make_path unless -e $env->{WEBPACK_OUT_DIR};
  return $ENV{MOJO_WEBPACK_DEBUG} ? warn "[Webpack] Cannot write to $env->{WEBPACK_OUT_DIR}\n" : 1
    unless -w $env->{WEBPACK_OUT_DIR};

  my $config_file = $self->{files}{'webpack.config.js'}[1];
  my @cmd = $ENV{MOJO_WEBPACK_BINARY} || path($config_file->dirname, qw(node_modules .bin webpack))->to_string;
  push @cmd, '--config' => $config_file->to_string;
  push @cmd, '--progress', '--profile', '--verbose' if $ENV{MOJO_WEBPACK_VERBOSE};
  push @cmd, split /\s+/, +($ENV{MOJO_WEBPACK_ARGS} || '');
  warn "[Webpack] @cmd\n" if $ENV{MOJO_WEBPACK_DEBUG};

  my $run_with = (grep {/--watch/} @cmd) ? 'exec' : 'system';
  my $CWD = Mojolicious::Plugin::Webpack::CWD->new($config_file->dirname);
  { local %ENV = %$env; $run_with eq 'exec' ? exec @cmd : system @cmd }
  die "[Webpack] $run_with @cmd: $!" if $!;

  # Register generated assets if webpack was run with system above
  $self->_register_assets;
}

sub _share_dir {
  state $share = path(path(__FILE__)->dirname, 'Webpack');
}

sub _webpack_environment {
  my $self = shift;
  my %env  = %ENV;

  $env{WEBPACK_ASSETS_DIR} = $self->assets_dir;
  $env{WEBPACK_OUT_DIR}    = $self->out_dir;
  $env{WEBPACK_SHARE_DIR}   //= $self->_share_dir;
  $env{WEBPACK_SOURCE_MAPS} //= $self->{source_maps} // 1;
  $env{uc "WEBPACK_RULE_FOR_$_"} = 1 for @{$self->{process}};

  return \%env;
}

package    # hide from pause
  Mojolicious::Plugin::Webpack::CWD;

sub new { _chdir(bless([$_[2] || Mojo::File->new->to_string], $_[0]), $_[1]) }
sub _chdir { chdir $_[1] or die "[Webpack] chdir $_[1]: $!"; $_[0] }
sub DESTROY { $_[0]->_chdir($_[0]->[0]) }

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Webpack - Mojolicious ♥ Webpack

=head1 SYNOPSIS

Check out
L<https://github.com/jhthorsen/mojolicious-plugin-webpack/tree/master/example>
for a working example.

=head2 Define assets

One or more assets need to be defined. The minimum is to create one
L<entry point|https://webpack.js.org/concepts/#entry> and add it to
the C<webpack.custom.js> file.

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

=head2 Application

Your lite or full app, need to load L<Mojolicious::Plugin::Webpack> and
tell it what kind of assets it should be able to process:

  $app->plugin(Webpack => {process => [qw(js css)]});

See L</register> for more config options.

=head2 Template

To include the generated assets in your template, you can use the L</asset>
helper:

  %= asset "my_app.css"
  %= asset "my_app.js"

=head2 Start application

You can start the application using C<daemon>, C<hypnotoad> or any Mojolicious
server you want, but if you want rapid development you should use
C<crushinator>, which is an alternative to C<morbo>:

  $ crushinator -h
  $ crushinator ./my_app.pl

=head1 DESCRIPTION

L<Mojolicious::Plugin::Webpack> is a L<Mojolicious> plugin to make it easier to
work with L<https://webpack.js.org/>.

Note that L<Mojolicious::Plugin::Webpack> is currently EXPERIMENTAL, and
changes might come without a warning.

=head1 HELPERS

=head2 asset

  warn $app->asset->out_dir;
  $c->asset("cool_beans.js", @args);
  %= asset "cool_beans.css", media => "print"

This helper will return the plugin instance if no arguments is passed in, or a
HTML tag created with either L<Mojolicious::Plugin::TagHelpers/javascript> or
L<Mojolicious::Plugin::TagHelpers/stylesheet> if a valid asset name is passed
in.

=head1 ATTRIBUTES

=head2 assets_dir

  $path = $self->assets_dir;

Holds a L<Mojo::File> object pointing to the private directoy where source
files are read from.

=head2 dependencies

  $hash_ref = $self->dependencies;

Holds a mapping between what this plugin can L</process> and which node modules
it depends on.

=head2 out_dir

  $path = $self->out_dir;

Holds a L<Mojo::File> object pointing to the public directoy where processed
assets are written to.

=head2 route

  $route = $self->route;

Holds a L<Mojolicious::Routes::Route> object that generates the URLs to a
processed asset.

=head1 METHODS

=head2 register

  $self->register($app, \%config);

The C<%config> passed when loading this plugin can have:

=head3 auto_cleanup

Set this to "0" if you want to keep the old files in L</out_dir>.

Default: enabled.

=head3 dependencies

Holds a hash ref with mapping between what to L</process> and which node module
that need to be installed to do so.

=head3 helper

Name of the helper that will be added to your application.

Default: C<"asset">.

=head3 process

A list of assets to process. Currently "css", "js", "sass" and "vue" is
supported.

Default: C<["js"]>.

=head3 source_maps

Set this to "0" if you do not want source maps generated.

Default: enabled.

=head1 AUTHOR

Jan Henning Thorsen

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojolicious::Plugin::AssetPack>.

=cut
