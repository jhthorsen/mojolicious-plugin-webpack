package Mojo::Alien::npm;
use Mojo::Base -base;

use Carp qw(croak);
use File::chdir;
use Mojo::File qw(path);
use Mojo::JSON qw(decode_json);

use constant DEBUG => ($ENV{MOJO_NPM_DEBUG} || $ENV{MOJO_WEBPACK_DEBUG}) && 1;

has command => sub {
  my $self = shift;
  return $ENV{MOJO_NPM_BINARY} ? [$ENV{MOJO_NPM_BINARY}] : ['npm'];
};

has config => sub { path->to_abs->child('package.json') };
has mode   => sub { $ENV{NODE_ENV} || 'development' };

sub init {
  my $self = shift;
  return $self if -r $self->config;
  $self->_run(qw(init -y));
  croak "$self->{basename} init failed: @{[$self->config]} was not generated." unless -r $self->config;
  return $self;
}

sub install {
  my ($self, $name, $info) = @_;
  croak "Can't install packages without package.json" unless -w $self->config;

  # Install everything
  do { $self->_run('install'); return $self } unless $name;

  # Install specific package
  $name = sprintf '%s@%s', $name, $info->{version} if $info->{version};
  my $type = sprintf '--save-%s', $info->{type} || 'dev';
  $self->_run('install', $name, $type);
  return $self;
}

sub dependency_info {
  my ($self, $name) = @_;
  croak "Can't get dependency info without package.json" unless -r $self->config;

  my $node_modules = $self->config->dirname->child('node_modules');
  return undef unless -d $node_modules;

  my ($package, $v) = ($self->_package);
  return {type => 'prod',     version => $v} if $v = $package->{dependencies}{$name};
  return {type => 'dev',      version => $v} if $v = $package->{devDependencies}{$name};
  return {type => 'optional', version => $v} if $v = $package->{optionalDependencies}{$name};
  return undef;
}

sub _package {
  my $self = shift;
  return $self->{package} ||= decode_json $self->config->slurp;
}

sub _run {
  my $self = shift;
  my @cmd  = (@{$self->command}, @_);
  $self->{basename} ||= path($cmd[0])->basename;
  local $CWD = $self->config->dirname->to_string;
  local $ENV{NODE_ENV} = $self->mode;
  warn "[NPM] cd $CWD && @cmd\n" if DEBUG;
  open my $NPM, '-|', @cmd or die "Can't fork @cmd: $!";
  return $NPM if defined wantarray;
  map { DEBUG && print } <$NPM>;
}

1;

=encoding utf8

=head1 NAME

Mojo::Alien::npm - Runs the external nodejs program npm

=head1 SYNOPSIS

  use Mojo::Alien::npm;
  my $npm = Mojo::Alien::npm->new;

  $npm->init;
  $npm->install;

=head1 DESCRIPTION

L<Mojo::Alien::webpack> is a class for runnig the external nodejs program
L<npm|https://npmjs.com/>.

=head1 ATTRIBUTES

=head2 command

  $array_ref = $npm->command;
  $npm = $npm->command(['npm']);

The path to the npm executable. Default is "npm". The C<MOJO_NPM_BINARY>
environment variable can be set to change the default.

=head2 config

  $path = $npm->config;
  $npm = $npm->config(path->to_abs->child('package.json'));

Holds an I</absolute> path to "package.json".

=head2 mode

  $str = $npm->mode;
  $npm = $npm->mode('development');

Should be either "development" or "production". Will be used as "NODE_ENV"
environment variable when calling "npm".

=head1 METHODS

=head2 dependency_info

  $info = $npm->dependency_info('package-name');

Used to get information from L</config> about a given package. This will return
C<undef> if the pacakge is unknown or if L</install> has not yet been called.
C<$info> will look like this:

  {
    type => 'prod',     # "dev", "optional" or "prod"
    version => '0.1.2', # the version from package.json
  }

=head2 init

  $npm->init;

Used to create a default L</config> file.

=head2 install

  $npm->install;
  $npm->install('package-name');
  $npm->install('package-name', {type => 'prod', version => '0.1.2'});

Installs either all modules from L</config> or a given package by name. An
additional C<$info> hash can also be provided.

=head1 SEE ALSO

L<Mojolicious::Plugin::Webpack>.

=cut
