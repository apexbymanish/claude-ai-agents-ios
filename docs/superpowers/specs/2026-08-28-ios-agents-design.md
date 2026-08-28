# claude-ai-agents-ios — Design Spec

Date: 2026-08-28

## Purpose

A drop-in collection of Claude Code subagents (plus supporting Skills and
templates) that turn Claude Code into a specialized iOS development team.
An iOS developer copies `.claude/agents/` (and optionally `.claude/skills/`,
`CLAUDE.md.template`) into their own project, and Claude Code automatically
routes iOS-specific work to the right specialist based on each agent's
`description` trigger phrases.

This is a content/prompt-engineering deliverable, not an app: the
"product" is a set of well-written Markdown agent definitions.

## Repository structure

```
claude-ai-agents-ios/
├── README.md                          # what this is, install, roster, handoffs
├── CLAUDE.md.template                 # project-context template for adopters
├── .claude/
│   ├── agents/
│   │   ├── ios-architect.md
│   │   ├── ios-unit-test-engineer.md
│   │   ├── ios-ui-test-engineer.md
│   │   ├── ios-memory-performance-engineer.md
│   │   ├── ios-ux-reviewer.md
│   │   └── ios-legacy-auditor.md
│   └── skills/
│       ├── ios-legacy-mapping/SKILL.md
│       └── ios-testing-strategy/SKILL.md
└── docs/
    └── superpowers/specs/2026-08-28-ios-agents-design.md   (this file)
```

## Agent roster

Each agent file has: YAML frontmatter (`name`, `description` with explicit
trigger phrases, `tools` scoped to least privilege for the role, optional
`model`), then a body with: expertise summary, a numbered "when consulted"
checklist, and concrete Swift-code-level guidance. Format follows the
convention established in the `claude-code-ios-dev-guide` reference
(frontmatter + expertise + checklist), adapted per-agent below.

1. **ios-architect** — Tools: Read, Grep, Glob, Write, Edit.
   Triggers: new feature/module, "how should I structure this", refactor
   requests, dependency injection questions.
   Covers: MVVM/Clean/VIPER selection rationale (not dogma — matches
   pattern to team/codebase size), modularization (SPM local packages),
   Swift Concurrency (actors, `Sendable`, structured concurrency),
   SwiftData vs Core Data decision criteria, navigation architecture.

2. **ios-unit-test-engineer** — Tools: Read, Grep, Glob, Write, Edit, Bash
   (scoped to `xcodebuild`/`swift test`).
   Triggers: "write tests", "add test coverage", TDD requests, reviewing
   existing tests.
   Covers: XCTest and Swift Testing (`@Test`, `#expect`), dependency
   injection seams for testability, mocking/stubbing patterns, what NOT
   to test (implementation details), coverage strategy prioritized by
   business-logic risk rather than raw %.

3. **ios-ui-test-engineer** — Tools: Read, Grep, Glob, Write, Edit, Bash
   (scoped to `xcodebuild`/simulator commands).
   Triggers: UI test requests, flaky UI test debugging, accessibility
   testing.
   Covers: XCUITest structure (Page Object pattern), accessibility
   identifiers as the stable selector strategy, snapshot testing setup,
   diagnosing flakiness (animation/async waits vs sleeps), CI simulator
   considerations.

4. **ios-memory-performance-engineer** — Tools: Read, Grep, Glob, Bash
   (Instruments/leaks-adjacent commands), Edit.
   Triggers: "memory leak", "app is slow", "why is memory growing",
   launch-time complaints.
   Covers: ARC retain-cycle patterns (closures capturing `self`,
   delegate cycles — `weak`/`unowned` judgment), Instruments workflows
   (Leaks, Allocations, Time Profiler) described as a procedure since
   Claude can't run Instruments itself, image/cache memory (downsampling,
   `NSCache` limits), Swift Concurrency data races and actor isolation
   costs, app launch time budget.

5. **ios-ux-reviewer** — Tools: Read, Grep, Glob (read-only; this agent
   critiques, doesn't rewrite UI unasked).
   Triggers: new screen/UI review requests, "does this look right",
   design-consistency questions.
   Grounded in: Apple Human Interface Guidelines (platform conventions,
   SF Symbols, Dynamic Type, dark mode, safe areas, motion/haptics as
   meaning not decoration), Dieter Rams' ten principles of good design as
   the underlying philosophy (useful, understandable, unobtrusive,
   honest, long-lasting, thorough down to the last detail, environmentally
   considerate = performance/battery-conscious UI, as little design as
   possible), Nielsen Norman Group usability heuristics (visibility of
   system status, consistency, error prevention, recognition over
   recall). Checklist walks: information hierarchy → platform-native
   conventions → accessibility (VoiceOver, contrast, tap targets ≥44pt,
   Dynamic Type) → motion/haptics purposefulness → consistency with rest
   of app. Explicitly instructed to distinguish "different from stock
   iOS" (fine, if intentional) from "violates platform/accessibility
   conventions" (a real problem).

6. **ios-legacy-auditor** — Tools: Read, Grep, Glob, Bash (read-only
   inspection commands only — `find`, `grep`, `wc`, no Write/Edit).
   Triggers: "explore this codebase", "no documentation", "old project",
   onboarding onto an unfamiliar app.
   Covers: inventorying targets/schemes, detecting the architecture
   actually in use (not assumed — greps for patterns like delegate counts,
   Massive View Controller signs, singleton usage), flagging Obj-C↔Swift
   bridging points and bridging-header health, mapping module/dependency
   boundaries, and producing a generated summary doc (suitable to seed
   a project's own `CLAUDE.md`) rather than editing the codebase itself.

## Supporting Skills

- **ios-legacy-mapping** (`.claude/skills/ios-legacy-mapping/SKILL.md`) —
  step-by-step procedure backing `ios-legacy-auditor`: inventory →
  detect architecture pattern → flag bridging points → produce doc.
  Referenced by the auditor agent rather than duplicating the procedure
  inline.
- **ios-testing-strategy** (`.claude/skills/ios-testing-strategy/SKILL.md`)
  — step-by-step procedure backing both test agents: identify seams →
  inject test doubles → write test → verify the test actually fails
  without the fix (red-green) → check coverage delta.

## Templates & docs

- **CLAUDE.md.template** — placeholders for platform/min iOS version,
  architecture pattern, package manager, notes on any legacy Obj-C/UIKit
  areas and their bridging status, so the roster of agents has accurate
  project context to read on session start.
- **README.md** — what this is, install instructions (copy `.claude/`
  folders into a project, or symlink for multiple projects), the roster
  table, and a short "how they hand off to each other" section (e.g.
  architect proposes structure → test engineers write tests against it →
  ux-reviewer checks the resulting screens → legacy-auditor is the
  entry point for an existing unfamiliar codebase instead of architect).

## Validation approach

No automated test suite (the deliverable is prompt text). Instead, a
self-review checklist applied to every agent/skill file before commit:

1. Frontmatter is valid YAML with required fields.
2. `description` contains concrete trigger phrases (not just a category
   label) so auto-selection actually fires on realistic user requests.
3. `tools` grant matches least privilege for the role (read-only agents
   have no Write/Edit; auditor has no mutation tools at all).
4. No contradicting guidance between agents (e.g. architect and
   ux-reviewer agree on when SwiftUI vs UIKit is appropriate).
5. Body gives concrete, Swift-code-level guidance, not generic platitudes
   — every checklist item should be actionable.

## Out of scope

- No custom slash commands (roster covers the need via auto-invoked
  agents/skills).
- No MCP server integration/config (adopters may already use
  XcodeBuildMCP; this repo doesn't bundle or require it).
- No CI/lint tooling to validate the Markdown files automatically —
  self-review is manual per file, matching the small size of this repo.
