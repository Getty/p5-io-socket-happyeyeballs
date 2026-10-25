use strict;
use warnings;
use Test::More;
use Socket qw( SOCK_STREAM SOL_SOCKET SO_REUSEADDR );

eval { require Net::EmptyPort; 1 }
  or plan skip_all => 'Net::EmptyPort required';

use IO::Socket::INET;
use IO::Socket::HappyEyeballs;

my $listener = IO::Socket::INET->new(
  Listen => 5, LocalAddr => '127.0.0.1', LocalPort => 0, Proto => 'tcp')
  or die "listen: $!";
my $peer_port = $listener->sockport;

my $local_port = Net::EmptyPort::empty_port();

my $sock = IO::Socket::HappyEyeballs->new(
  PeerHost  => '127.0.0.1',
  PeerPort  => $peer_port,
  LocalHost => '127.0.0.1',
  LocalPort => $local_port,
  ReuseAddr => 1,
  Type      => SOCK_STREAM,
  Proto     => 'tcp',
  Timeout   => 5,
);
ok($sock, 'connected with socket options') or diag $@;

is($sock->sockport, $local_port, 'LocalPort reached the socket');
is($sock->sockhost, '127.0.0.1', 'LocalHost reached the socket');
is($sock->socktype, SOCK_STREAM, 'the socket has the requested type');
ok($sock->sockopt(SO_REUSEADDR), 'ReuseAddr reached the socket');

my $taken = IO::Socket::INET->new(
  Listen => 1, LocalAddr => '127.0.0.1', LocalPort => $local_port,
  Proto => 'tcp');
ok(!$taken, 'the local port is taken after the connection');

# Options that belong to the parent class are refused, not dropped
eval {
  IO::Socket::HappyEyeballs->new(
    PeerHost => '127.0.0.1', PeerPort => $peer_port, Listen => 5);
};
like($@, qr/Listen is not supported/, 'Listen is refused');

eval {
  IO::Socket::HappyEyeballs->new(
    PeerHost => '127.0.0.1', PeerPort => $peer_port,
    Type => Socket::SOCK_DGRAM());
};
like($@, qr/Type must be SOCK_STREAM/, 'a datagram Type is refused');

done_testing;
