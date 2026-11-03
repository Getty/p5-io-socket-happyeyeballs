# IO-Socket-HappyEyeballs House Rules

The shared house rules come from skilletor — bundle `getty-cpan-dist@getty`: engineering
discipline, the delegation lock, the publish gate, karr coordination, CPAN release. They load
as `.claude/rules/.local.*.md`; if they are missing, run `skilletor sync` and publish nothing
until they load. This file adds what is true only here, and wins where it differs.

## What this repo is

RFC 8305 Happy Eyeballs v2 connection algorithm. One class, one module, plain OO.

## Agent team

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `io-socket-happyeyeballs-worker` (default) |
| Commits, `Changes`, card → done, pre-release audit | `io-socket-happyeyeballs-release-manager` |
| Read-only research, audit, gap analysis | `io-socket-happyeyeballs-worker` ("read-only, change nothing") |

Behavior-relevant = anything in `lib/`, the tests, the algorithm (interleaving, attempt delay,
first-wins racing, family cache) and the global override — not `README.md` or `Changes` wording.

## Release

The version lives in the module (`our $VERSION`, rewritten by the bundle at release time); the
unreleased `Changes` section carries the entries of the next release.

## Hazards — the algorithm is the product, don't regress it silently

- **The algorithm:** resolve, interleave the families, start one attempt every 250 ms, return
  the first socket that connects, close the rest, remember the winning family. The `-override`
  flag replaces `IO::Socket::IP->new` for the whole process. A change to any of that is
  user-visible: it needs a `Changes` entry and a test.
- **The override is process-global and irreversible** — a change there needs a test that shows
  what still works after the patch.
- **Every change to the attempt logic needs a test that fails without it** — `t/10-attempt-delay.t`,
  `t/11-last-resort-reachable.t` and `t/12-socket-options.t` show the pattern.
- **One class, one module.** A second module, a second object system or a plugin system needs
  a card that asks for it.

## Perl specifics — reference, don't restate

Module loading, sub style, error handling, cpanfile pinning, per-file version declarations and
POD conventions live in `getty-perl-core` and `getty-perl-pod`; the distribution layout and the
release path live in `perl-release-dist-ini` and `getty-perl-release-author-getty`. The
algorithm, the override and the pinned behaviours live in `io-socket-happyeyeballs-core`.
