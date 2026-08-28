---
name: ios-evidence-reporting
description: Standard for reporting task outcomes with verifiable evidence instead of confident prose. Use whenever concluding any iOS agent task — implementation, testing, review, audit, or architecture consultation — before claiming something works, passes, is safe, or is well-structured.
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

### Example: an implementation/verification task

(`ios-feature-implementation`, `ios-unit-test-engineer`,
`ios-ui-test-engineer`, `ios-memory-performance-engineer`)

```
BUILD        ✓ xcodebuild succeeded
TEST         ✓ 24/24 tests passed
AVAILABILITY ✓ iOS 14 compatible (checked 2 new API calls)
MEMORY       ✓ static inspection, no retain-cycle pattern found
             ⚠ Instruments not executed — recommend an Allocations pass
PERFORMANCE  ✓ no blocking main-thread work introduced
SECURITY     ✓ token stored via existing Keychain wrapper
DIFF         ✓ 4 files changed, reviewed end to end
```

### Example: a read-only review/audit/consult task

(`ios-architect`, `ios-ux-reviewer`, `ios-legacy-auditor`)

```
ACCESSIBILITY   ⚠ 1 tap target below 44pt (ProfileView.swift:82)
CONVENTIONS     ✓ matches platform navigation patterns
CONSISTENCY     ✓ reuses existing button style throughout
ARCHITECTURE    ✓ MVC-in-name-only (38 VCs >400 lines, 210 .shared refs)
TESTABILITY     ⚠ proposed design not yet unit-tested — no test exists
SECURITY        ⚠ 3 leads to verify — see Security signals section
```

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
