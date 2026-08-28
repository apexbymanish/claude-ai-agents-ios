---
name: ios-performance-measurement
description: Procedure for confirming a performance fix actually worked, with a real number, instead of asserting improvement from reading code. Use when asked to "make this faster", "why is this slow", "measure this", "profile this", or before/after a performance change needs proof it helped.
---

# iOS Performance Measurement

Reading code can find a *plausible* cause. It cannot tell you whether
fixing that cause actually moved the number, or whether a completely
different layer was the real bottleneck. This procedure exists for the
gap between "this should be faster" and "this is faster, by this much."

Two rules govern everything below:

1. **Take the number before changing anything.** Change first and the
   only thing left to say afterward is "feels faster" — which is not a
   number and cannot be defended.
2. **The first guess is usually wrong.** Main-thread decoding and heavy
   layout are the guesses everyone reaches for first; they're the
   actual cause less than half the time in practice. Trust the
   measurement over the guess, and drop the guess the moment a
   measurement contradicts it — don't go looking for a reason the
   measurement must be wrong instead.

## 1. Pin down the reproduction before measuring anything

A before/after comparison is only valid if the same action happened
under the same conditions both times. Write these down first:

- Device and OS version — and whether it's a simulator or a physical
  device (see below; this materially changes what the numbers mean).
- Build configuration — Debug vs. Release. Release has optimizations
  Debug doesn't; a Debug-measured improvement can vanish or invert in
  Release.
- Data scale — how many list items, how many/how large images.
- The exact action sequence — launch → tap X → scroll N times.
- Cache state — cold (first launch) or warm (second+ launch).

**Simulator numbers are not device numbers.** A simulator runs on the
Mac's own CPU/GPU, so raw computation looks fast, I/O behaves
differently, and there is no thermal throttling, no real memory
pressure, and no real network latency to contend with.

| | Simulator | Physical device |
|---|---|---|
| Use for | quickly checking direction (better/worse) | **claiming an actual number** |
| Trustworthy for | relative comparison only | absolute values |
| Missing entirely | thermal state, memory pressure, low-end hardware | — |

Any number reported to the user should come from a physical device
where one is available. If only a simulator is available, say so
explicitly in the report rather than presenting the number as if it
were a device measurement.

**Only one simulator should be booted while timing anything.**
Simulators share the Mac's CPU/GPU, so a second one running in parallel
inflates every timing number (though not counts — request counts and
allocation counts don't drift with contention). Check before timing:

```sh
xcrun simctl list devices booted | grep -c Booted   # should be 1
```

Never run `xcrun simctl shutdown all`, `erase all`, or
`delete unavailable` to clear the field — those are global and can
destroy a simulator another session or another person on the same
Mac is actively using. Target a specific UDID instead.

## 2. Choose the one thing to measure, and say why

Trying to measure everything at once measures nothing usefully. Pick
the layer most likely to explain the complaint, and state the
reasoning before touching anything:

| Layer | What moves | Points here when |
|---|---|---|
| Launch | time to first frame, time to interactive | app-start work is piling up sequentially |
| Tap response (hang) | count and duration of stalls | tapped, and the response is late — main thread is held |
| Scroll (hitch) | dropped-frame count, overage per frame | scrolling/transitions stutter — render missed its budget |
| Network | request count, **duplicate requests**, response size/time | request count scales with the number of items on screen |
| Decoding | decode time, which thread it runs on | decoding is happening on the main thread |
| Main-thread occupancy | time held per event | any event handler exceeds ~16.7ms (60Hz frame budget) |
| Object churn | heavy objects created in a repeated path | formatters/regexes/encoders instantiated inside a loop |
| Memory | cache hit/miss, retained size after leaving a screen | memory doesn't come back down after navigating away |

If both hangs and hitches are plausible, capture both from the same
on-device trace and compare their totals, not just their counts — a
2:1 count ratio can hide an 8:1 duration ratio, and duration is what
tells you which layer to actually fix.

## 3. Prefer a path that needs no code before writing any

Check this table before adding a single line of instrumentation code —
several common questions are answerable with zero app changes:

| Question | Answer without touching the app |
|---|---|
| Request count, duplicates, response size/time | An HTTP proxy on the device/simulator |
| Hangs, hitches, launch time, thermal state | An on-device Instruments trace |
| Actual retained memory after leaving a screen | An on-device memory sample of the running process |
| Pure algorithmic/logic time | A test target with timed assertions |

Instrumentation code is only justified for what's left after this
table: screen-entry latency tied to a specific line, which thread a
decode runs on, or a count of objects created in a specific hot path.
Code you add for measurement has to be removed later — every line
you avoid adding is a line you don't have to remember to remove.

## 4. If you do add instrumentation, keep it removable

- **Never let it survive into a release build.** Wrap it so the string
  work itself doesn't happen outside debug builds:

```swift
enum Measure {
    /// The label is @autoclosure so a Release build never even builds the string.
    static func mark(_ label: @autoclosure () -> String) {
        #if DEBUG
        print("[MEASURE] \(label())")
        #endif
    }

    static func time<T>(_ label: @autoclosure () -> String, _ body: () throws -> T) rethrows -> T {
        #if DEBUG
        let start = DispatchTime.now().uptimeNanoseconds
        defer {
            let ms = Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000
            print("[MEASURE] \(label()) \(String(format: "%.1f", ms))ms")
        }
        #endif
        return try body()
    }
}
```

- **Count at the exact point that matters, not near it.** If the fix is
  a cache meant to cut network calls, count at the actual network call
  site — behind the cache — not at the call site the view uses. Counting
  in front of the cache produces an identical before/after number even
  when the cache works, because the view still asks every time; only
  what's behind the cache actually drops.
- **Keep every measurement hook in one file.** Scattered across ten
  files, some are guaranteed to survive the cleanup pass.

## 5. Record progress in a file the repo will never track

A measure → fix → re-measure loop rarely finishes in one pass. Put the
running record somewhere git-ignored, and verify it's actually ignored
— don't trust a directory-level check:

```sh
git status --porcelain path/to/your/scratch-file.md   # must print nothing
```

`git check-ignore` on a directory alone is not sufficient and can give
the wrong answer two ways: it reports a directory as *not* ignored even
when a rule matches every file inside it, and a file can still be
tracked from before the ignore rule existed even though new files in
that directory are correctly ignored. Asking about the actual file you
created with `git status --porcelain` is the only check that can't lie.

```markdown
## Reproduction
Device / config / data scale / action sequence / cache state

## Before (measured 2026-08-28)
| Metric | Value |
|---|---|
| Network requests | 219 |
| Main-thread time per tap | 31ms |

## Hypotheses ruled out
- Main-thread image decoding — measured at 1-2ms in the background. Not it.

## Progress
- [x] Instrumentation added
- [x] Before measured
- [ ] Fix applied          ← stopped here
- [ ] After measured
- [ ] Instrumentation removed (verified via `strings`)
```

## 6. Re-measure with the identical reproduction, side by side

```
                       Before   After
Network requests         219      12
Cache hits                 0     207
Main-thread time/tap     31ms     7ms
```

Timing numbers drift run to run — take the median of three runs and
discard the first (cold caches and first-launch costs distort it).
Count numbers (requests, allocations) don't drift the same way; one
clean run is enough for those.

## 7. Confirm the instrumentation is actually gone

```sh
# Should print 0 — no measurement strings survived into the release binary
strings YourApp.app/YourApp | grep -c 'MEASURE'

# Any remaining call sites should be intentional, not leftover scaffolding
grep -rn 'Measure\.' --include='*.swift' . | wc -l
```

## Handing off mid-investigation

If the cause turns out to live in a different layer than expected:

| Finding | Hand off to |
|---|---|
| The fix requires restructuring, not just a hot-path change | `ios-architect` |
| Nothing guards this path from regressing again | `ios-unit-test-engineer` |
| The suspected cause is a retain cycle or unbounded cache, not raw speed | `knowledge/memory-performance.md` (same agent, different section) |

Never mix a structural change into the same commit as a measured
performance fix — if a regression shows up later, mixing them makes it
impossible to tell which change caused it.

## Reporting

```
## Reproduction
[conditions]

## First hypothesis
[what you guessed] → [confirmed / ruled out, with the number]

## Actual cause
[layer + evidence, file:line where relevant]

## Before / after
[table]

## Not measured
[anything skipped, stated as skipped — never implied as verified]
```

Close with the `ios-evidence-reporting` skill's status block, and grade
every line: a number from an actual run is `(executed)`; a cause you
haven't run anything to confirm yet is `(static)` at best, or `⚠` if
you haven't checked it at all. Never write a percentage without the
raw before/after numbers next to it — "219 → 12" can be checked; "94%
faster" on its own cannot.
