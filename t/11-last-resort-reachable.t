use strict;
use warnings;
use Test::More;
use Socket qw( AF_INET SOCK_STREAM IPPROTO_TCP pack_sockaddr_in inet_aton );
use Time::HiRes ();

eval { require Net::EmptyPort; 1 }
  or plan skip_all => 'Net::EmptyPort required';

use IO::Socket::HappyEyeballs;

my $class = 'IO::Socket::HappyEyeballs';
my $orig  = \&IO::Socket::HappyEyeballs::_last_resort_synthesis;
my $calls = 0;
my @synth;     # what the stubbed synthesis hands back

{
  no warnings 'redefine';
  *IO::Socket::HappyEyeballs::_last_resort_synthesis = sub {
    $calls++;
    return @synth ? [ @synth ] : ();
  };
}

$class->last_resort_delay(0);

sub addr_for { {
  family   => AF_INET,
  socktype => SOCK_STREAM,
  protocol => IPPROTO_TCP,
  addr     => pack_sockaddr_in($_[0], inet_aton('127.0.0.1')),
} }

my $closed = Net::EmptyPort::empty_port();

# The synthesis runs after the first round has failed
{
  $calls = 0;
  my $sock = $class->new(
    PeerHost => '127.0.0.1', PeerPort => $closed, Timeout => 5);
  ok(!$sock, 'connection to a closed port fails');
  is($calls, 1, 'last resort synthesis was called exactly once');
}

# Addresses it returns are attempted, and the connection can win through them
{
  my $listener = IO::Socket::INET->new(
    Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0, Proto => 'tcp')
    or die "listen: $!";
  @synth = (addr_for($listener->sockport));
  $calls = 0;
  my $sock = IO::Socket::HappyEyeballs::_attempt_connections(
    [ addr_for($closed) ], 0.05, 5, {}, '127.0.0.1', $closed);
  ok($sock, 'a synthesized address connects after the first round failed');
  is($calls, 1, 'synthesis called once');
  @synth = ();
}

# Addresses that were already attempted are not tried again
{
  my @attempts;
  no warnings 'redefine';
  my $real = \&IO::Socket::HappyEyeballs::_start_connect;
  local *IO::Socket::HappyEyeballs::_start_connect = sub {
    push @attempts, $_[0]{addr};
    return $real->(@_);
  };
  @synth = (addr_for($closed));
  my $sock = IO::Socket::HappyEyeballs::_attempt_connections(
    [ addr_for($closed) ], 0.05, 5, {}, '127.0.0.1', $closed);
  ok(!$sock, 'no connection');
  is(scalar @attempts, 1, 'a repeated address is attempted once only');
  @synth = ();
}

# The deadline still applies: a synthesis that would start after it is dropped
{
  no warnings 'redefine';
  *IO::Socket::HappyEyeballs::_last_resort_synthesis = $orig;
  $class->last_resort_delay(10);
  my $start = Time::HiRes::time();
  my $sock = IO::Socket::HappyEyeballs::_attempt_connections(
    [ addr_for($closed) ], 0.05, 1, {}, 'localhost', $closed);
  ok(!$sock, 'no connection');
  cmp_ok(Time::HiRes::time() - $start, '<', 2,
    'synthesis after the deadline is abandoned');
}

# Without a NAT64 prefix the fallback has nothing to offer
{
  no warnings 'redefine';
  local *IO::Socket::HappyEyeballs::_detect_nat64_prefix = sub { return };
  $class->last_resort_delay(0);
  my $result = $orig->('localhost', $closed, {},
    Time::HiRes::time(), Time::HiRes::time() + 5);
  ok(!$result || !@$result, 'no NAT64 prefix: no addresses offered');
}

done_testing;
