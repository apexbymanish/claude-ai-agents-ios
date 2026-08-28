# claude-ai-agents-ios

A drop-in set of [Claude Code](https://claude.com/claude-code) subagents
and Skills that turn Claude Code into a specialized iOS development
team: architecture, unit testing, UI testing, memory/performance,
UI/UX review, security, App Store readiness, and legacy-codebase
auditing — each one auto-invoked based on what you ask, no manual
switching required.

## What's included

### Subagents (`.claude/agents/`)

| Agent | Invoked when you... | Tools |
|---|---|---|
| `ios-architect` | start a new feature/module, ask "how should I structure this", plan a refactor, choose MVVM/Clean/VIPER, decide on DI or SwiftData vs. Core Data | Read, Grep, Glob, Write, Edit, Skill |
| `ios-unit-test-engineer` | ask for tests, test coverage, TDD, or to make code testable | Read, Grep, Glob, Write, Edit, Bash, Skill |
| `ios-ui-test-engineer` | ask for UI tests, debug a flaky UI test, or set up snapshot testing | Read, Grep, Glob, Write, Edit, Bash, Skill |
| `ios-memory-performance-engineer` | report a leak, growing memory, slow scrolling, or slow launch | Read, Grep, Glob, Bash, Edit, Skill |
| `ios-ux-reviewer` | ask for a UI/UX review or design-consistency check | Read, Grep, Glob, Skill (read-only) |
| `ios-legacy-auditor` | onboard onto an unfamiliar, undocumented, or large legacy codebase | Read, Grep, Glob, Bash, Skill (read-only) |
| `ios-security-reviewer` | ask for a security review, "is this secure", vulnerability check, or auth/session audit | Read, Grep, Glob, Bash, Skill (read-only) |
| `ios-app-store-reviewer` | ask "is this ready to submit", "will this get rejected", or to check App Store compliance | Read, Grep, Glob, Bash, Skill (read-only) |

### Skills (`.claude/skills/`)

| Skill | Backs | Purpose |
|---|---|---|
| `ios-testing-strategy` | `ios-unit-test-engineer`, `ios-ui-test-engineer` | Concrete seams → test-double → red/green procedure |
| `ios-legacy-mapping` | `ios-legacy-auditor` | Concrete inventory → detect-architecture → bridging-risk → security-signal → summary-doc procedure |
| `ios-security-review` | `ios-security-reviewer` | 8-area audit: storage/privacy → transport → authN/session → input validation → deep links → third-party SDKs → code hygiene → entitlements |
| `ios-app-store-readiness` | `ios-app-store-reviewer` | Pre-submission audit: privacy manifest → export compliance → permission descriptions → App Tracking Transparency → Sign in with Apple parity → unused entitlements → rejection triggers |
| `ios-feature-implementation` | General — fires on any feature request, works alongside `ios-architect` | Inspect existing code, business logic, API/connectivity behavior, and security posture → explain before touching files → implement → verify (build, tests, retain cycles, memory, performance, security) → report |
| `ios-evidence-reporting` | All 8 agents — fires whenever any of them concludes a task | Standard status-block format (`✓` verified / `⚠` unverified / `✗` failed) so no agent claims something works, passes, or is safe without evidence already shown in its report |

### Knowledge library (`knowledge/`)

Deep reference material lives here instead of inside agent bodies, so
each agent stays focused on *when to act* and *what procedure to
follow*, while the knowledge file is the *source of truth for what to
check*. Agents read these with the `Read` tool when relevant — no
extra configuration needed.

| File | Referenced by | Contents |
|---|---|---|
| `memory-performance.md` | `ios-memory-performance-engineer` | ARC/Instruments/image/concurrency fundamentals plus framework-specific patterns (RxSwift, WKWebView, PDFKit, Core Data, Firebase, CocoaPods, Keychain, third-party presentation libraries, UICollectionView/UITableView, SwiftUI/UIKit bridges, AVFoundation, CoreLocation, URLSession) |
| `architecture-patterns.md` | `ios-architect` | Pattern/decision criteria: MVVM/Clean/VIPER, Swift Concurrency, modularization, persistence, navigation, DI, security-aware structure |
| `design-philosophy.md` | `ios-ux-reviewer` | Apple HIG, Dieter Rams' ten principles applied to iOS, Nielsen Norman Group heuristics, and the named references list |

### Template

- `CLAUDE.md.template` — copy to your project root as `CLAUDE.md` and
  fill in the placeholders (or let `ios-legacy-auditor` generate the
  architecture section for you on an unfamiliar codebase).

## Install

Copy what you need into your iOS project's repo root:

```bash
# From this repo, copy into your project:
mkdir -p /path/to/your-ios-project/.claude
cp -r .claude/agents /path/to/your-ios-project/.claude/
cp -r .claude/skills /path/to/your-ios-project/.claude/
cp -r knowledge /path/to/your-ios-project/knowledge
cp CLAUDE.md.template /path/to/your-ios-project/CLAUDE.md   # then edit it
```

```bash
# Or symlink instead of copying, to stay in sync across multiple projects:
ln -s /path/to/claude-ai-agents-ios/.claude/agents /path/to/your-ios-project/.claude/agents
ln -s /path/to/claude-ai-agents-ios/.claude/skills /path/to/your-ios-project/.claude/skills
ln -s /path/to/claude-ai-agents-ios/knowledge /path/to/your-ios-project/knowledge
```

The `knowledge/` folder must live at your project's repo root (alongside
`.claude/`) — agents reference it by that relative path.

For personal (cross-project) use instead of per-project, copy into
`~/.claude/agents/` and `~/.claude/skills/` instead — Claude Code merges
personal and project-level agents/skills automatically. Note that
`knowledge/` is referenced as a repo-relative path, so for personal use
you'd still need `knowledge/` present at each project's root (symlinking
it in per-project is simplest).

Nothing else to configure — Claude Code reads each agent's `description`
frontmatter and invokes the right one automatically based on your
request.

## How they hand off to each other

A typical flow, though you never need to invoke any of this by name:

1. **Unfamiliar/undocumented codebase?** Start with `ios-legacy-auditor`
   — it maps the real architecture and produces a summary you can drop
   into `CLAUDE.md`, before anything else touches the code.
2. **New feature/module?** `ios-architect` proposes structure and flags
   whether the design is unit-testable; `ios-feature-implementation`
   then drives the actual build — inspecting existing business logic
   first, explaining the plan before touching files, implementing
   against the agreed structure, and verifying (build, tests, memory,
   performance) before reporting done.
3. **Need tests?** `ios-unit-test-engineer` for logic, `ios-ui-test-engineer`
   for user flows — both follow the same seams → red/green discipline
   from `ios-testing-strategy`.
4. **New or changed screen?** `ios-ux-reviewer` checks it against Apple's
   Human Interface Guidelines and the underlying design philosophy
   before you ship it.
5. **Something feels slow or leaks memory?** `ios-memory-performance-engineer`
   reads the code for static causes first, and gives you the exact
   Instruments procedure when it can't be found by reading alone.
6. **Want a security check?** `ios-security-reviewer` runs a dedicated
   8-area audit (storage, transport, auth, input validation, deep
   links, dependencies, code hygiene, entitlements); `ios-architect`,
   `ios-legacy-auditor`, and `ios-feature-implementation` also flag
   lighter, scoped security concerns as part of their own work and
   point here for anything that warrants a full audit.
7. **About to submit to the App Store?** `ios-app-store-reviewer` checks
   the code-visible submission blockers (privacy manifest, permission
   descriptions, export compliance, Sign in with Apple parity) — it's a
   separate concern from `ios-security-reviewer` even though they share
   some ground (entitlements, transport security), so run both before a
   release if either is relevant.

## Evidence over assertion

Every agent in this repo ends its report with the `ios-evidence-reporting`
skill's status block instead of a bare "Done! It works." A build-and-test
task shows `BUILD`/`TEST`/`DIFF` lines backed by real command output; a
read-only review shows `ACCESSIBILITY`/`ARCHITECTURE`/`SECURITY` lines
backed by file:line citations and counts. Anything not actually checked
is marked `⚠` and explained — never silently dropped, never asserted
as if it were verified.

## Design philosophy

`ios-ux-reviewer` in particular is grounded in named sources rather than
asserted taste: Apple's Human Interface Guidelines, Dieter Rams' ten
principles of good design, Don Norman's *The Design of Everyday Things*,
Nielsen Norman Group's usability heuristics, and *Refactoring UI* for
concrete visual judgment calls. See `knowledge/design-philosophy.md`
for how each is applied to iOS specifically.
