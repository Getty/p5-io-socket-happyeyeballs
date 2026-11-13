# IO-Socket-HappyEyeballs

RFC 8305 "Happy Eyeballs Version 2" for Perl: a socket class that races the IPv6
and IPv4 paths of a dual-stack host in parallel instead of trying them one after
the other, so a broken IPv6 route costs a quarter of a second instead of a minute.
Used directly, or globally through the `-override` import flag, which makes every
`IO::Socket::IP->new` in the process use the algorithm.

One module — `lib/IO/Socket/HappyEyeballs.pm` — a plain subclass of
`IO::Socket::IP`, plus its tests in `t/`. The algorithm, the override and the
pinned behaviours live in skill `io-socket-happyeyeballs-core` — they are not repeated here.

Released to CPAN as `IO-Socket-HappyEyeballs`, built with `Dist::Zilla` via
`[@Author::GETTY]`.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself —
the principle is the shared rule `agent-delegation` (skilletor bundle
`getty-cpan-dist@getty`); lanes and hazards are in
`.claude/rules/io-socket-happyeyeballs-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `io-socket-happyeyeballs-worker` (default) |
| Commits, `Changes`, card → done, pre-release audit | `io-socket-happyeyeballs-release-manager` |

The agents carry their skills via `briefing.skills` (see `.claude/agents/`); the
main agent delegates rather than loading them. Skill sources live under
`.claude/skills/` — `getty-perl-core`, `getty-perl-pod` and the karr skills are
installed from the shared sources; `io-socket-happyeyeballs-core` is owned by this
repo.

Work is coordinated on the repo's `karr` board (`karr board`).

## State of the code

The suite covers the surroundings — sorting, caching, the accessors, the blocking
modes, the override with a subclass and a UDP socket — and the attempt logic: the
250 ms attempt delay, the reachable RFC 8305 §7.2 last resort, and the socket
options reaching every attempt. The live test is skipped unless
`TEST_HAPPYEYEBALLS_LIVE=1`.

The distribution is release-shaped: `LICENSE`, `Changes` with an unreleased
section, `README.md`, `cpanfile` and a GitHub Actions workflow
(`.github/workflows/ci.yml`) are in the tree, and `dist.ini` carries the header and
`[@Author::GETTY]`.
