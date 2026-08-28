# claude-ai-agents-ios

A drop-in set of [Claude Code](https://claude.com/claude-code) subagents
and Skills that turn Claude Code into a specialized iOS development
team: architecture, unit testing, UI testing, memory/performance,
UI/UX review, and legacy-codebase auditing — each one auto-invoked
based on what you ask, no manual switching required.

## What's included

### Subagents (`.claude/agents/`)

| Agent | Invoked when you... | Tools |
|---|---|---|
| `ios-architect` | start a new feature/module, ask "how should I structure this", plan a refactor, choose MVVM/Clean/VIPER, decide on DI or SwiftData vs. Core Data | Read, Grep, Glob, Write, Edit |
| `ios-unit-test-engineer` | ask for tests, test coverage, TDD, or to make code testable | Read, Grep, Glob, Write, Edit, Bash, Skill |
| `ios-ui-test-engineer` | ask for UI tests, debug a flaky UI test, or set up snapshot testing | Read, Grep, Glob, Write, Edit, Bash, Skill |
| `ios-memory-performance-engineer` | report a leak, growing memory, slow scrolling, or slow launch | Read, Grep, Glob, Bash, Edit |
| `ios-ux-reviewer` | ask for a UI/UX review or design-consistency check | Read, Grep, Glob (read-only) |
| `ios-legacy-auditor` | onboard onto an unfamiliar, undocumented, or large legacy codebase | Read, Grep, Glob, Bash, Skill (read-only) |

### Skills (`.claude/skills/`)

| Skill | Backs | Purpose |
|---|---|---|
| `ios-testing-strategy` | `ios-unit-test-engineer`, `ios-ui-test-engineer` | Concrete seams → test-double → red/green procedure |
| `ios-legacy-mapping` | `ios-legacy-auditor` | Concrete inventory → detect-architecture → bridging-risk → summary-doc procedure |

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
cp CLAUDE.md.template /path/to/your-ios-project/CLAUDE.md   # then edit it
```

```bash
# Or symlink instead of copying, to stay in sync across multiple projects:
ln -s /path/to/claude-ai-agents-ios/.claude/agents /path/to/your-ios-project/.claude/agents
ln -s /path/to/claude-ai-agents-ios/.claude/skills /path/to/your-ios-project/.claude/skills
```

For personal (cross-project) use instead of per-project, copy into
`~/.claude/agents/` and `~/.claude/skills/` instead — Claude Code merges
personal and project-level agents/skills automatically.

Nothing else to configure — Claude Code reads each agent's `description`
frontmatter and invokes the right one automatically based on your
request.

## How they hand off to each other

A typical flow, though you never need to invoke any of this by name:

1. **Unfamiliar/undocumented codebase?** Start with `ios-legacy-auditor`
   — it maps the real architecture and produces a summary you can drop
   into `CLAUDE.md`, before anything else touches the code.
2. **New feature/module?** `ios-architect` proposes structure and flags
   whether the design is unit-testable.
3. **Need tests?** `ios-unit-test-engineer` for logic, `ios-ui-test-engineer`
   for user flows — both follow the same seams → red/green discipline
   from `ios-testing-strategy`.
4. **New or changed screen?** `ios-ux-reviewer` checks it against Apple's
   Human Interface Guidelines and the underlying design philosophy
   before you ship it.
5. **Something feels slow or leaks memory?** `ios-memory-performance-engineer`
   reads the code for static causes first, and gives you the exact
   Instruments procedure when it can't be found by reading alone.

## Design philosophy

`ios-ux-reviewer` in particular is grounded in named sources rather than
asserted taste: Apple's Human Interface Guidelines, Dieter Rams' ten
principles of good design, Don Norman's *The Design of Everyday Things*,
Nielsen Norman Group's usability heuristics, and *Refactoring UI* for
concrete visual judgment calls. See the agent file itself for how each
is applied to iOS specifically.
