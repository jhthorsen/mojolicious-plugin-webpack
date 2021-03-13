use Mojo::Base -strict;
use Mojo::Alien::npm;
use Mojo::File qw(path);
use Test::More;

plan skip_all => 'TEST_NPM=1' unless $ENV{TEST_NPM} or $ENV{TEST_ALL};

my $remove_tree = $ENV{TEST_CONTINUE} ? sub { } : 'remove_tree';
chdir(my $work_dir = path(local => path($0)->basename)->tap($remove_tree)->make_path) or die $!;
note "work_dir=$work_dir";

sub maybe (&) { local $TODO = 'TEST_CONTINUE=1' if $ENV{TEST_CONTINUE}; shift->(); }

subtest 'basic' => sub {
  my $npm = Mojo::Alien::npm->new;
  is_deeply $npm->command, ['npm'], 'command';
  is $npm->mode, 'development', 'mode';

  eval { $npm->install };
  maybe { like $@, qr{Can't install packages}, 'install' };

  eval { $npm->dependencies };
  maybe { like $@, qr{Can't get dependency info}, 'dependencies' };
};

subtest 'init' => sub {
  my $npm = Mojo::Alien::npm->new;
  maybe { ok !-r $npm->config, 'config does not exist' };
  is $npm->init, $npm, 'init';
  ok -r $npm->config, 'config created';
  is $npm->init, $npm, 'init can be called again';

  maybe { is_deeply [keys %{$npm->dependencies}], [], 'dependencies' };
};

subtest 'install' => sub {
  my $npm = Mojo::Alien::npm->new;
  is $npm->install, $npm, 'install';
  is $npm->install('jsonhtmlify', {type => 'prod'}), $npm, 'install jsonhtmlify';

  my $dependencies = $npm->dependencies;
  is_deeply [keys %{$npm->dependencies}], [qw(jsonhtmlify)], 'dependencies';

  my $info = $dependencies->{jsonhtmlify};
  is $info->{type},     'prod', 'jsonhtmlify type';
  ok $info->{required}, "jsonhtmlify required $info->{required}";
  ok $info->{version},  "jsonhtmlify version $info->{version}";
};

done_testing;
