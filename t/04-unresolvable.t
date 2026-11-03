#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use IO::Socket::HappyEyeballs;

# The trailing dot makes the name absolute: a resolver search domain with a
# wildcard record cannot complete it into a name that resolves.
my $sock = IO::Socket::HappyEyeballs->new(
  PeerHost => 'this-host-does-not-exist.invalid.',
  PeerPort => 80,
  Timeout  => 2,
);

ok(!$sock, 'connection to unresolvable host fails');
like($@, qr/(?:no addresses found|getaddrinfo failed)/, 'error message set');

done_testing;
