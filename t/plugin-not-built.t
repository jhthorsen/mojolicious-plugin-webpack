use Mojo::Base -strict;
use Mojo::File qw(path);
use Test::More;

BEGIN {
  plan skip_all => $@ || $!
    unless eval { chdir($ENV{MOJO_HOME} = path(local => path($0)->basename)->to_abs->remove_tree->make_path) };
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
