use Mojo::Base -strict;
use Mojo::File qw(path);
use Test::More;

BEGIN {
  require Mojo::Alien::npm;
  note sprintf 'work_dir=%s', Mojo::Alien::npm->_setup_working_directory;
  $ENV{MOJO_HOME} = path->to_string;
  note "MOJO_HOME=$ENV{MOJO_HOME}";
}

use Mojolicious::Lite;
my $warn = '';
local $SIG{__WARN__} = sub { $warn .= $_[0] };
plugin webpack => {};
like $warn, qr{has been run for mode "development"}, 'asset_map.development.json not built';

app->mode('production');
plugin webpack => {};
like $warn, qr{has been run for mode "production"}, 'asset_map.production.json not built';

done_testing;
