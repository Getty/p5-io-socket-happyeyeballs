# IO-Socket-HappyEyeballs

RFC 8305 "Happy Eyeballs Version 2" for Perl: a socket class that races the IPv6
and IPv4 paths of a dual-stack host in parallel instead of trying them one after
the other, so a broken IPv6 route costs a quarter of a second instead of a minute.
Used directly, or globally through the `-override` import flag, which makes every
`IO::Socket::IP->new` in the process use the algorithm.

One module — `lib/IO/Socket/HappyEyeballs.pm` — a plain subclass of
`IO::Socket::IP`, plus eleven tests. The algorithm, the override and the known
traps live in skill `io-socket-happyeyeballs-core` — they are not repeated here.

Released to CPAN as `IO-Socket-HappyEyeballs`, built with `Dist::Zilla` via
`[@Author::GETTY]`.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself —
the principle and the lane boundaries are in
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

The suite is green: 51 tests in 11 files, the live test skipped unless
`TEST_HAPPYEYEBALLS_LIVE=1`. The suite covers the surroundings well — sorting,
caching, the accessors, the blocking modes, the override with a subclass and a UDP
socket — and the racing itself not at all.

Four defects are known and recorded on the board: the RFC 8305 §7.2 last resort
branch is unreachable, the socket options never reach the socket, the attempt
delay is not the specified 250 ms, and the IPv4 fallback repeats the first round.
The release path is blocked as well: there is no `LICENSE` file, and the
unreleased section of `Changes` is empty.
