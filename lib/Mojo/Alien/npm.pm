package Mojo::Alien::npm;
use Mojo::Base -base;

use Carp qw(croak);
use File::chdir;
use Mojo::File qw(path);
use Mojo::JSON qw(decode_json false);

use constant DEBUG => ($ENV{MOJO_NPM_DEBUG} || $ENV{MOJO_WEBPACK_DEBUG}) && 1;

has command => sub {
  my $self = shift;
  return $ENV{MOJO_NPM_BINARY} ? [$ENV{MOJO_NPM_BINARY}] : ['npm'];
};

has config => sub { path->to_abs->child('package.json') };
has mode   => sub { $ENV{NODE_ENV} || 'development' };

sub dependencies {
  my $self = shift;
  croak "Can't get dependency info without package.json" unless -r $self->config;

  my $NPM          = $self->_run(qw(ls --json --parseable --silent));
  my $dependencies = decode_json(join '', <$NPM>)->{dependencies} || {};

  my $package = decode_json $self->config->slurp;
  my %types   = (devDependencies => 'dev', dependencies => 'prod', optionalDependencies => 'optional');
  for my $type (qw(optionalDependencies devDependencies dependencies)) {
    for my $name (keys %{$package->{$type}}) {
      $dependencies->{$name}{required} = $package->{$type}{$name};
      $dependencies->{$name}{type}     = $types{$type};
      $dependencies->{$name}{version} //= '';
    }
  }

  return $dependencies;
}

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

=head2 dependencies

  $dependencies = $npm->dependencies;

Used to get dependencies from L</config> combined with information from
C<npm ls>. The returned hash-ref looks like this:

  {
    "package-name" => {
      required => $str,  # version from package.json
      type     => $str,  # dev, optional or prod
      version  => $str,  # installed version
      ...
    },
    ...
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
