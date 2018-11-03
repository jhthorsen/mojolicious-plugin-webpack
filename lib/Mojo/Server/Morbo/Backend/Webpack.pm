package Mojo::Server::Morbo::Backend::Webpack;

use Mojo::Base eval 'require Mojo::Server::Morbo::Backend::Inotify;1'
  ? 'Mojo::Server::Morbo::Backend::Inotify'
  : 'Mojo::Server::Morbo::Backend::Poll';

sub modified_files {
  my $self = shift;
  $self->_spawn_webpack unless $self->{webpack_pid};
  return $self->SUPER::modified_files(@_);
}

sub _reap_webpack {
  my ($manager, $daemon) = @_;
  return if kill 0, $manager;
  my $webpack = $daemon->app->asset->daemon;
  return $daemon->ioloop->stop unless $webpack and kill 0, $webpack->pid;
  kill $webpack->pid;
}

sub _spawn_webpack {
  my $self = shift;

  # Manager
  $ENV{MOJO_WEBPACK_ARGS} = '';    # Prevent webpack from running in parent
  my $manager = $$;
  die "Can't fork: $!" unless defined(my $pid = $self->{webpack_pid} = fork);
  return if $pid;

  # Webpack worker
  $ENV{MOJO_WEBPACK_ARGS} = '--watch';    # Make webpack run as a daemon
  my $daemon = Mojo::Server::Daemon->new;
  $daemon->load_app($self->watch->[0]);
  $daemon->ioloop->recurring(1 => sub { _reap_webpack($manager, $daemon) });
  $daemon->run;
  exit 0;
}

1;
