# IO-Socket-HappyEyeballs House Rules

Apply to every task in this repo unless explicitly overridden. Bias: caution over speed on
non-trivial work; use judgment on trivial tasks. Loaded automatically at launch, same priority
as `CLAUDE.md`. The subagents get their conventions from the force-loaded skills — this file is
for the orchestrating agent.

## Engineering discipline

1. **Think before coding** — State assumptions. When uncertain, ask rather than guess.
   Push back when a simpler approach exists. Name what is unclear.
2. **Simplicity first** — One class, one module. A second module, a second object
   system or a plugin system needs a card that asks for it.
3. **Surgical changes** — Touch only what you must. Don't "improve" adjacent code,
   comments or formatting. Match the existing layout.
4. **Tests verify intent, not just behavior** — The suite is green, but it does not
   cover the racing. Every change to the attempt logic needs a test that fails it.
5. **Match the codebase's conventions, even if you disagree** — Conformance > taste.
   Surface a harmful convention; don't fork silently. This class is plain OO.
6. **Fail loud** — "Done" is wrong if anything was skipped silently. "Tests pass" is
   wrong if any were skipped. Surface uncertainty, don't hide it.
7. **A red test is a claim before it is a failure** — Before changing code to turn a
   test green, say what it asserts and whether the fix keeps or replaces that claim.

## Delegation

- **You can spawn subagents** (orchestrating main agent): Do NOT touch behavior-relevant
  code yourself — delegate. Your lane: coordinate, inspect, plan, review diffs, run
  tests, edit non-behavioral docs. Why: only the `io-socket-happyeyeballs-*` agents get
  their skills force-loaded via `briefing.skills`; you get no briefing and would touch
  the address interleaving and the attempt timing with too little context.

  | Task | Agent |
  |---|---|
  | Implement / refactor / debug behavior-relevant code | `io-socket-happyeyeballs-worker` (default) |
  | Commits, `Changes`, card → done, pre-release audit | `io-socket-happyeyeballs-release-manager` |

- **You cannot spawn subagents** (you ARE an `io-socket-happyeyeballs-*` agent): The
  delegation lock does not apply — implement, refactor, debug and test per these rules.

Behavior-relevant = anything in `lib/`, the tests, the algorithm (interleaving, attempt
delay, first-wins racing, family cache) and the global override — not `README.md` or
`Changes` wording.

**Only `io-socket-happyeyeballs-release-manager` commits**: a worker leaves a commit-ready
tree and hands its card to `review`; the release-manager cuts the commit and closes it.

## The algorithm is the product — don't regress it silently

Resolve, interleave the families, start one attempt every 250 ms, return the first socket
that connects, close the rest, remember the winning family. The `-override` flag replaces
`IO::Socket::IP->new` for the whole process. A change to any of that is user-visible: it
needs a `Changes` entry and a test. The override is process-global and irreversible, so a
change there needs a test that shows what still works after the patch.

## Coordination — karr board (always in scope)

Ticket coordination is the orchestrating agent's job, so `karr` is always in scope — just
use it, don't invoke the skill first. Board state lives in `refs/karr/*`.

- `karr list --compact` / `karr board` — open work · `karr show ID` — detail
- `karr create "Title" --priority high --tags a,b --body '…'` — new ticket
- `karr edit ID -a "note"` · `--claim NAME` · `--block "why"` — update
- `karr move ID in-progress --claim NAME` — start · `karr handoff ID --claim NAME --note "…"` — to review
- mutating commands auto-sync; `karr sync --pull|--push` for explicit exchange

Life cycle: claim and hand out → the worker notes and ends at `review` → the release-manager
commits and moves it to `done`.

**Serialize board mutations when fanning out.** Keep implementation work parallel, then
loop the board writes one after another — N at once is a resource event, not cheap.

## Release — never without permission

`dzil build` / `dzil test` / `prove -lr t/` are fine anytime. `dzil release` and any CPAN upload are
STRICTLY forbidden without the maintainer's explicit go-ahead — even if a plan lists "release" as
the next step. Stop and ask. The version lives in the module; the unreleased `Changes` is empty.

## Public issues — never act without instruction

`karr` is the internal agent board, churned freely. The GitHub issue tracker carries real people's
reports under the maintainer's account. Never act on a public issue on your own initiative — not even
to read it. Listing, viewing, commenting and closing are off without an explicit instruction.

## Perl specifics — reference, don't restate

Module loading, sub style, error handling, cpanfile pinning, per-file version declarations
and POD conventions live in `getty-perl-core` and `getty-perl-pod`; the distribution layout
and the release path live in `perl-release-dist-ini` and `getty-perl-release-author-getty`.
The algorithm, the override and the known traps live in `io-socket-happyeyeballs-core`.
