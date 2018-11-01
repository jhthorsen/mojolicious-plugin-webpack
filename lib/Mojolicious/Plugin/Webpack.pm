package Mojolicious::Plugin::Webpack;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::ByteStream 'b';

our $VERSION = '0.01';

sub register {
  my ($self, $app, $config) = @_;

  $self->_run_webpack($app, $config) if $ENV{MOJO_WEBPACK_BUILD} // 1;
  $app->helper(asset => sub { return b '<script>/* $c->asset("TODO") */</script>' });
}

sub _run_webpack {
  my ($self, $app, $config) = @_;
  my @cmd = $config->{bin} || $app->home->rel_file('node_modules/.bin/webpack');

  push @cmd, '--config' => $config->{config_file} || $app->home->rel_file('webpack.config.js');
  push @cmd, '--env' => $config->{env} // $app->mode;
  push @cmd, '--cache', '--progress' if ($config->{env} || $app->mode) eq 'development';
  push @cmd, '--hot', '--watch' if $config->{hot};
  push @cmd, '--profile', '--verbose' if $ENV{MOJO_WEBPACK_VERBOSE};

  warn "[Webpack] @cmd\n" if 1 or $ENV{MOJO_WEBPACK_VERBOSE};
  system @cmd;
}

1;
