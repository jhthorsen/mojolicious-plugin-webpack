use Mojo::Base -strict;
use Mojo::Alien::webpack;
use Mojo::File qw(path);
use Test::More;

plan skip_all => 'TEST_WEBPACK=1' unless $ENV{TEST_WEBPACK} or $ENV{TEST_ALL};
$ENV{TEST_MOJO_WEBPACK} = 1;

my $remove_tree = $ENV{TEST_CONTINUE} ? sub { } : 'remove_tree';
chdir(my $work_dir = path(local => path($0)->basename)->tap($remove_tree)->make_path) or die $!;
note "work_dir=$work_dir";

sub maybe (&) { local $TODO = 'TEST_CONTINUE=1' if $ENV{TEST_CONTINUE}; shift->(); }

subtest 'basic' => sub {
  my $webpack = Mojo::Alien::webpack->new;
  is $webpack->mode, 'development', 'mode';

  isa_ok $webpack->npm, 'Mojo::Alien::npm', 'npm';
  is $webpack->npm->config->dirname, $webpack->config->dirname, 'npm config location' or diag $webpack->config;

  isa_ok $webpack->config, 'Mojo::File', 'config';
  maybe { ok !-e $webpack->config, 'config' };

  is $webpack->pid, 0, 'pid';
  is $webpack->stop, $webpack, 'stop';
};

subtest 'build' => sub {
  my $webpack = Mojo::Alien::webpack->new;
  is $webpack->build, $webpack, 'build';

  local $webpack->command->[0] = '/no/such/bin/webpack';
  eval { $webpack->build };
  like $@, qr(Can't run.*webpack), 'invalid command';
};

subtest 'watch' => sub {
  my $webpack = Mojo::Alien::webpack->new;
  ok !$webpack->pid, 'no pid';

  is $webpack->watch, $webpack, 'watch';

  note 'wating for process to watch';
  1 until $webpack->pid;

  eval { $webpack->build };
  like $@, qr{Can't call build}, 'cannot call watch and then build';

  note 'stop running process';
  is $webpack->stop, $webpack, 'stop';
  ok !$webpack->pid, 'stopped';

  local $webpack->command->[0] = '/no/such/bin/webpack';
  eval { $webpack->watch };
  like $@, qr(Can't run.*webpack), 'invalid command';
};

done_testing;
