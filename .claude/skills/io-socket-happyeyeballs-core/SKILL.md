---
name: io-socket-happyeyeballs-core
description: "Load before editing IO-Socket-HappyEyeballs — the RFC 8305 Happy Eyeballs v2 socket class: the address interleaving, the connection attempt delay, the address family cache, the global override and the traps that the last resort branch is unreachable and the socket options never reach the socket."
---

# IO::Socket::HappyEyeballs — core

A socket class that establishes TCP connections to dual-stack hosts the way
RFC 8305 ("Happy Eyeballs Version 2") prescribes: it races the address families
instead of trying them one after the other, so a broken IPv6 path costs a quarter
of a second instead of a minute.

The distribution ships **one module and eleven tests**:

| File | Role |
|---|---|
| `lib/IO/Socket/HappyEyeballs.pm` | the whole implementation — one class, roughly 500 lines |
| `t/00-load.t` | the module loads |
| `t/01-resolve-sort.t` | the address interleaving and the family cache |
| `t/02-connect-local.t` | a real connection to a local listener |
| `t/03-connect-refused.t` | a refused connection |
| `t/04-unresolvable.t` | a name that does not resolve |
| `t/05-cache.t` | the address family cache |
| `t/06-delay-config.t` | the delay accessor |
| `t/07-blocking-mode.t` | the blocking and non-blocking socket modes |
| `t/08-override.t` | the global override, incl. a `Net::HTTP` subclass and a UDP socket |
| `t/09-last-resort-synthesis.t` | the NAT64 synthesis helpers |
| `t/80-live-dual-stack.t` | a live test against a real host, skipped unless `TEST_HAPPYEYEBALLS_LIVE=1` |

There is no second module and no script. A change that touches anything but
`lib/IO/Socket/HappyEyeballs.pm` is probably not this distribution.

## The class

`IO::Socket::HappyEyeballs` is a **plain subclass of `IO::Socket::IP`**
(`use parent qw(IO::Socket::IP)`). It is not Moo and not Moose — there is no
attribute system here, the state lives in file-scoped variables, and the public
surface is a handful of class methods.

Public API:

| Entry point | Meaning |
|---|---|
| `IO::Socket::HappyEyeballs->new(%args)` | connect with the Happy Eyeballs algorithm |
| `use IO::Socket::HappyEyeballs -override` | make **every** `IO::Socket::IP->new` in the process use the algorithm |
| `->clear_cache` | drop the address family cache and the NAT64 prefix cache |
| `->connection_attempt_delay($s)` | get/set the delay between two attempts, default `0.250` |
| `->cache_ttl($s)` | get/set the lifetime of the family cache, default `600` |
| `->last_resort_delay($s)` | get/set the wait before the RFC 8305 §7.2 fallback, default `2` |

`new()` returns the connected socket, or `undef` with `$@` set. It croaks only
when `PeerHost`/`PeerAddr` or `PeerPort` are missing.

## The algorithm

1. **Resolve** the host with `getaddrinfo`, `AF_UNSPEC`, `SOCK_STREAM`,
   `AI_ADDRCONFIG`. If that yields nothing, the lookup is repeated without the
   flag, so a loopback-only host still resolves.
2. **Sort** the addresses by interleaving the families: IPv6, IPv4, IPv6, IPv4 …
   A cached family from an earlier successful connection wins the first slot.
3. **Attempt** — a non-blocking `connect()` per address, one attempt started
   every *connection attempt delay* (250 ms per RFC 8305 §5) while the earlier
   ones are still pending.
4. **First wins** — the first socket whose `SO_ERROR` is zero is returned, all
   other pending sockets are closed.
5. **Cache** the winning family under `host:port` for the cache TTL.

## The global override

`-override` replaces `IO::Socket::IP::new` and `IO::Socket::IP::configure` in
the `IO::Socket::IP` namespace for the rest of the process. Only outgoing TCP
is intercepted — a call with `PeerHost`/`PeerAddr` **and** `PeerPort` and no
conflicting protocol or socket type. Listeners, UDP and Unix sockets go to the
original `new`.

For a subclass the socket is reblessed into the subclass and `configure` is
called once; the patched `configure` sees the marker hash key and returns
without reconnecting, so `Net::HTTP` and friends keep their own setup and do
not open a second connection.

The override is **process-global and irreversible** — there is no uninstall.
That is the documented intent, but it is also why it belongs in exactly one
place in a program.

## The traps

Four things in this implementation do not do what their shape suggests. They are
known, they are not fixed, and they are the reason the class does not behave
exactly like the RFC describes.

1. **The §7.2 last resort branch is unreachable.** The branch requires that all
   addresses are exhausted and no attempt is pending — but that is exactly the
   state in which the `while` condition at the top of the loop is false, so the
   loop exits before the branch is ever read. `_last_resort_synthesis` is never
   called during a failed connection; the feature that the 0.002 release
   announced never runs.
2. **The socket options never reach the socket.** `_start_connect` creates a
   bare `IO::Socket::IP`, calls `socket()` and then `connect()` itself. Every
   option of `IO::Socket::IP` — `LocalAddr`, `LocalPort`, `ReuseAddr`, `Type`,
   `Proto` — is dropped on the floor, silently. Only `Blocking` survives, and
   only because `_restore_blocking` applies it afterwards.
3. **The attempt delay is not 250 ms.** The timing runs on `time()`, which has a
   one-second resolution, while the delay is a fraction of a second. The gap
   between two attempts is therefore whatever is left of the current second —
   measured between 0.1 s and 1.0 s instead of a fixed 0.25 s.
4. **The IPv4 fallback of the last resort path repeats the first round.** When
   no NAT64 prefix is found, `_last_resort_synthesis` returns the plain A
   records — the addresses the first round already used and that already
   failed. On a normal network that fallback is a no-op.

## Vocabulary

- **address family cache** — `host:port` to the family that won the last
  successful connection, with an expiry. It decides which family is tried
  first next time.
- **connection attempt delay** — the pause between two connection attempts,
  250 ms by default.
- **interleaving** — the ordering of the resolved addresses: one family, then
  the other, alternating.
- **last resort** — the RFC 8305 §7.2 fallback, taken after all initial
  attempts have failed: resolve A records only and synthesize IPv6 addresses
  through the NAT64 prefix.
- **NAT64 prefix** — the 96-bit prefix of the translator, discovered by
  resolving `ipv4only.arpa` (RFC 7050).

## Tests

`prove -lr t/` is green: 51 tests in 11 files, the live test skipped unless
`TEST_HAPPYEYEBALLS_LIVE=1`.

The suite is strong on the surroundings — sorting, caching, the accessors, the
blocking modes, the override with a subclass and a UDP socket — and silent on
the algorithm itself: **nothing tests the racing**, neither that the second
address is tried after the delay, nor that the first successful socket wins and
the others are closed. Any change to the attempt logic needs a test that fails
without it.

The tests reach into private subs (`_sort_addresses`, `_synthesize_nat64_addr`,
`_detect_nat64_prefix`, `_last_resort_synthesis`). That is the current style of
this distribution; keep it unless a card says otherwise.

## Distribution conventions

- `dist.ini` uses `[@Author::GETTY]`, so the POD follows that bundle's shortcut
  commands and the file carries a `# ABSTRACT:` line. It has.
- The requirements live in the `cpanfile` — the bundle reads them from there.
  `Socket` and `IO::Select` are core modules and are listed anyway.
- The module carries `our $VERSION = '0.003';`. It was bumped by hand after
  the 0.002 release; the `Changes` file still carries an empty unreleased
  section above the 0.002 entry.
- There is no `LICENSE` file in the repository. `dzil build` aborts because of
  it, and the file has to be **committed** — the bundle gathers only tracked
  files, so an untracked `LICENSE` fails with the identical message.
- The hand-written `README.md` stays out of the built distribution; the bundle
  excludes it by default and generates a `README` from the POD.
- The POD is hand written, with a manual `=head1 SUPPORT` style section at the
  end. The bundle generates `AUTHOR` and `COPYRIGHT` — see the house POD skill.
