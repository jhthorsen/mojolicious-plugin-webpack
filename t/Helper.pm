package t::Helper;
use Mojo::Base -strict;

use Mojo::File 'path';
use Mojolicious;
use Test::Mojo;
use Test::More;

our ($CLEANUP, $WORK_DIR);

sub cleanup_after { $CLEANUP = $_[0] }

sub t {
  my ($class, %config) = @_;
  my $app = Mojolicious->new;
  $ENV{MOJO_WEBPACK_ARGS} = delete $config{args} if defined $config{args};
  $app->plugin(Webpack => \%config);
  return Test::Mojo->new($app);
}

sub cwd {
  my $class = shift;
  mkdir($WORK_DIR = path(path(__FILE__)->dirname, @_)->to_abs);
  plan skip_all => "Cannot change to $WORK_DIR" unless chdir $WORK_DIR;
  return $WORK_DIR;
}

sub import {
  my $class  = shift;
  my $caller = caller;

  $_->import for qw(strict warnings utf8);
  feature->import(':5.10');

  eval <<"HERE" or die $@;
package $caller;
use Test::Mojo;
use Test::More;
1;
HERE
}

1;

END {
  $WORK_DIR->remove_tree if $WORK_DIR and $CLEANUP;
}
