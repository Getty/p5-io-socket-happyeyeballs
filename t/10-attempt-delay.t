use strict;
use warnings;
use Test::More;
use Socket qw( AF_INET SOCK_STREAM IPPROTO_TCP pack_sockaddr_in inet_aton );
use Time::HiRes ();

use IO::Socket::HappyEyeballs;

# Attempts that never complete: the read end of a pipe is never writable, so
# the loop keeps every attempt pending and only the delay paces the starts.
my @starts;
{
  no warnings 'redefine';
  *IO::Socket::HappyEyeballs::_start_connect = sub {
    push @starts, Time::HiRes::time();
    pipe(my $r, my $w) or die "pipe: $!";
    my $sock = IO::Socket::IP->new;
    open($sock, '<&=', fileno($r)) or die "fdopen: $!";
    ${*$sock}{keep} = [ $r, $w ];
    return $sock;
  };
}

my @addresses = map {
  {
    family   => AF_INET,
    socktype => SOCK_STREAM,
    protocol => IPPROTO_TCP,
    addr     => pack_sockaddr_in(80, inet_aton("192.0.2.$_")),
  }
} 1 .. 4;

my $delay = 0.05;
my $sock = IO::Socket::HappyEyeballs::_attempt_connections(
  \@addresses, $delay, 0.6, {}, 'test.invalid', 80);

ok(!$sock, 'no attempt connects');
is(scalar @starts, 4, 'all four attempts were started within the timeout');

for my $i (1 .. $#starts) {
  my $gap = $starts[$i] - $starts[$i - 1];
  cmp_ok($gap, '>=', $delay - 0.005, "gap $i is not shorter than the delay");
  cmp_ok($gap, '<', $delay + 0.04, "gap $i is close to the delay");
}

done_testing;
