---
name: ios-evidence-reporting
description: Standard for reporting task outcomes with verifiable evidence instead of confident prose. Use before writing "it works", "done", "this is safe", or "this is well-structured" at the end of any iOS agent task — implementation, testing, review, audit, or architecture consultation.
---

# iOS Evidence-Based Reporting

Never write "Done!", "This works correctly", "This is safe", or any
other confident-sounding claim without evidence backing it somewhere in
the same report. A claim is not more trustworthy for being phrased
confidently — it's less, if nothing backs it.

## The status block

End every report with a compact status block: one line per category
relevant to *your* domain, each marked:

- `✓` — verified: backed by an actual command's output, a specific
  file:line you read, or a concrete count you produced — shown
  elsewhere in the same report, not just asserted here.
- `⚠` — not verified: say why in the same line, and what would verify
  it. Never silently drop a category that matters because you didn't
  check it — mark it `⚠`, don't omit it.
- `✗` — checked, and it failed or a real problem was found.

Pick the categories from your own agent's checklist. Don't force
categories that don't apply to your role — a read-only review agent has
no `BUILD` line; an architecture consult has no `TEST` line. Don't pad
the block with an irrelevant category just to look thorough.

### Two grades of `✓`

Not every `✓` carries the same weight, and collapsing them loses
information. Grade each `✓` by how it was actually backed:

- **`(static)`** — backed by reading the code and tracing the logic to a
  specific file:line, with no command run against the running app. Real
  evidence, but a static read can miss what only shows up at runtime —
  a retain cycle depends on the actual object graph at runtime, not
  just the absence of `[weak self]` in the source.
- **`(executed)`** — backed by actually running something against the
  built app or its tests and reading real output: a test suite, a
  build, an Instruments trace, a before/after measurement. Strictly
  stronger than `(static)` for anything behavioral — memory,
  performance, and timing claims in particular.

A claim like "no memory leak" earns `✓ (static)` from reading the code
alone — never upgrade it to a bare `✓` or imply `(executed)` when
nothing was actually run. For any category where the gap between
reading code and running it actually matters (memory and performance
usually qualify), say which grade backs the claim instead of leaving it
ambiguous.

### Example: an implementation/verification task

(`ios-feature-implementation`, `ios-unit-test-engineer`,
`ios-ui-test-engineer`, `ios-memory-performance-engineer`)

```
BUILD        ✓ (executed) xcodebuild succeeded
TEST         ✓ (executed) 24/24 tests passed
AVAILABILITY ✓ (static) iOS 14 compatible (checked 2 new API calls)
MEMORY       ✓ (static) no retain-cycle pattern found
             ⚠ nothing executed — recommend an Instruments Allocations pass
PERFORMANCE  ✓ (static) no blocking main-thread work introduced
SECURITY     ✓ (static) token stored via existing Keychain wrapper
DIFF         ✓ (executed) 4 files changed, reviewed end to end
```

### Example: a read-only review/audit/consult task

(`ios-architect`, `ios-ux-reviewer`, `ios-legacy-auditor`)

```
ACCESSIBILITY   ⚠ 1 tap target below 44pt (ProfileView.swift:82)
CONVENTIONS     ✓ (static) matches platform navigation patterns
CONSISTENCY     ✓ (static) reuses existing button style throughout
ARCHITECTURE    ✓ (executed) MVC-in-name-only (38 VCs >400 lines via grep,
                210 .shared refs via grep)
TESTABILITY     ⚠ proposed design not yet unit-tested — no test exists
SECURITY        ⚠ 3 leads to verify — see Security signals section
```

Note `ARCHITECTURE` above is graded `(executed)`, not `(static)` — the
counts came from actually running `grep`/`wc` and reading real command
output, not from eyeballing files. Running a command and reading its
output is `(executed)` even for an otherwise read-only agent; `(static)`
is reserved for claims backed only by reading source with no command run.

## What this is not

- Not a replacement for the full prose report each agent already
  produces — it's a compact summary at the end, and every `✓`/`⚠`/`✗`
  in it must be traceable to something stated in the body above it.
- Not a demand to run tools you don't have. A read-only agent marks
  `⚠` honestly rather than fabricating a check it couldn't perform, or
  claiming a command-based check it has no tool to run.
- Not a reason to invent categories. If nothing in your domain checklist
  is relevant to a category, leave that category out entirely rather
  than including it marked `⚠` for the sake of completeness.
