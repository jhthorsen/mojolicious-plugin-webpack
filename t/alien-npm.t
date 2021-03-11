use Mojo::Base -strict;
use Mojo::Alien::npm;
use Mojo::File qw(path);
use Test::More;

plan skip_all => 'TEST_NPM=1' unless $ENV{TEST_NPM} or $ENV{TEST_ALL};

my $remove_tree = $ENV{TEST_CONTINUE} ? sub { } : 'remove_tree';
chdir(my $work_dir = path(local => path($0)->basename)->tap($remove_tree)->make_path) or die $!;

subtest 'basic' => sub {
  my $npm = Mojo::Alien::npm->new;
  is_deeply $npm->command, ['npm'], 'command';
  is $npm->mode, 'development', 'mode';

  eval { $npm->install };
  like $@, qr{Can't install packages}, 'install';

  eval { $npm->dependency_info };
  like $@, qr{Can't get dependency info}, 'dependency_info';
};

subtest 'init' => sub {
  my $npm = Mojo::Alien::npm->new;
  ok !-r $npm->config, 'config does not exist';
  is $npm->init, $npm, 'init';
  ok -r $npm->config, 'config created';
  is $npm->init, $npm, 'init can be called again';

  is $npm->dependency_info('jsonhtmlify'), undef, 'dependency_info';
};

subtest 'install' => sub {
  my $npm = Mojo::Alien::npm->new;
  is $npm->install, $npm, 'install';
  is $npm->dependency_info('jsonhtmlify'), undef, 'dependency_info';
  is $npm->install('jsonhtmlify', {type => 'prod'}), $npm, 'install jsonhtmlify';

  my $info = $npm->dependency_info('jsonhtmlify');
  is $info->{type}, 'prod', 'dependency_info jsonhtmlify type';
  ok $info->{version}, "dependency_info jsonhtmlify $info->{version}";
};

done_testing;
