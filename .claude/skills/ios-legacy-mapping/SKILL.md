---
name: ios-legacy-mapping
description: Step-by-step procedure for mapping an undocumented, unfamiliar, or large legacy iOS codebase (Objective-C, UIKit, SwiftUI, or a mix) before making changes. Use when onboarding onto a project with no CLAUDE.md, no architecture docs, or when asked to "explore this codebase" or "figure out how this app is structured".
---

# iOS Legacy Codebase Mapping

A read-only reconnaissance procedure. Do not modify code while running
this — the output is a document, not a refactor.

## 1. Inventory targets and schemes

```bash
find . -name "*.xcodeproj" -o -name "*.xcworkspace"
xcodebuild -list -project <Project>.xcodeproj   # or -workspace
```

Note every target (app, extensions, frameworks, test targets) and which
scheme builds what. A large app often has more targets than the obvious
main one (share extensions, widgets, watch app).

## 2. Detect the architecture actually in use — don't assume

Codebases rarely match what their README claims (if they have one at
all). Grep for signal, don't guess:

```bash
# Massive View Controller smell
grep -rlZ "class.*ViewController" --include="*.swift" --include="*.m" . \
  | xargs -0 wc -l | sort -rn | head -20

# Singleton usage density
grep -rn "\.shared\b" --include="*.swift" . | wc -l

# Delegate pattern density (common in older UIKit code)
grep -rn "Delegate" --include="*.swift" --include="*.h" . | wc -l

# MVVM signal
grep -rl "ViewModel" --include="*.swift" . | wc -l
```

A file count over ~400-500 lines for view controllers, high singleton
density, and low ViewModel presence together indicate a Massive View
Controller / MVC-in-name-only codebase regardless of what any doc claims.

## 3. Flag Objective-C ↔ Swift bridging points

```bash
find . -name "*-Bridging-Header.h"
find . -name "*.h" -o -name "*.m" | wc -l   # Obj-C surface area
grep -rl "@objc" --include="*.swift" . | head -20
```

For each bridging header found, read it and note which Obj-C types are
exposed to Swift — these are the highest-risk edit points (changes on
either side can silently break the other without a compiler error on
both sides in mixed-language files).

## 4. Map module and dependency boundaries

```bash
find . -name "Package.swift"
find . -name "Podfile"
find . -name "*.podspec"
```

Note whether the app is a single monolithic target, uses local SPM
packages, or uses CocoaPods/Carthage — this determines how safely code
can be moved or extracted later.

## 5. Produce the summary document

Write findings as a `CLAUDE.md`-ready summary with these sections:

```markdown
## Codebase Summary (generated)

- **Targets:** [list from step 1]
- **Architecture actually in use:** [finding from step 2, with evidence:
  "42 view controllers over 500 lines, 180 `.shared` references,
  6 files referencing ViewModel" — not just a label]
- **Legacy Objective-C surface:** [bridging headers found, approximate
  `.m`/`.h` file count, riskiest bridging points]
- **Module structure:** [monolith / SPM packages / CocoaPods, and which]
- **Suggested entry points for new work:** [the most decoupled, best-
  tested area to build on, if one exists]
```

Hand this to the user as the seed for their project's own `CLAUDE.md` —
don't silently create or overwrite one without being asked.
