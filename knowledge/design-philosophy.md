# iOS Design Philosophy

Referenced by `ios-ux-reviewer`. This is the reasoning that grounds its
judgment — read this before applying the agent's Review checklist, not
as a substitute for it.

Judgment is grounded in three sources, applied together rather than any
one in isolation:

1. **Apple's Human Interface Guidelines (HIG)** — the platform-specific
   contract users already have with every other app on their device.
   Deviating from it has a real cost (learned behavior broken), so
   deviations must be intentional and justified, not accidental.
2. **Dieter Rams' ten principles of good design** — the underlying
   philosophy HIG itself descends from. Applied to iOS specifically:
   - *Good design is innovative* — but innovation in service of the
     task, not novelty for its own sake in navigation/gestures users
     must relearn.
   - *Good design makes a product useful* — every screen element earns
     its place by serving the user's actual task on that screen.
   - *Good design is aesthetic* — visual quality is not optional
     polish; it affects perceived trustworthiness and usability.
   - *Good design makes a product understandable* — the UI should
     communicate its own function; if a screen needs an onboarding
     tooltip to be usable, the design has a hierarchy problem.
   - *Good design is unobtrusive* — chrome and decoration should not
     compete with the user's content and task for attention.
   - *Good design is honest* — a UI should not imply capability that
     doesn't exist (a spinner over instant fake progress, a disabled-
     looking button that's actually tappable).
   - *Good design is long-lasting* — prefer platform-native components
     that survive OS visual refreshes over bespoke chrome that will look
     dated in two years.
   - *Good design is thorough down to the last detail* — empty states,
     error states, loading states, and edge-case content lengths (very
     long names, zero items) are part of the design, not an
     afterthought.
   - *Good design is environmentally considerate* — on iOS this means
     battery/CPU/network cost: avoid unnecessary animation loops,
     polling, or over-fetching in service of a visual effect.
   - *Good design is as little design as possible* — "less, but
     better": when in doubt, cut the element rather than add a setting
     to configure it.
3. **Nielsen Norman Group usability heuristics**, the ones most relevant
   to mobile: visibility of system status (loading/progress always
   visible), consistency and standards (this screen behaves like the
   rest of this app and like the platform), error prevention over error
   messaging, recognition over recall (don't make users remember state
   from a previous screen), and flexibility/efficiency for repeat use
   (shortcuts for power users that don't get in a new user's way).

## References

Ground recommendations in these named sources when it strengthens the
feedback, rather than asserting taste as fact:
- Apple Human Interface Guidelines (developer.apple.com/design/
  human-interface-guidelines) — the primary platform authority.
- Dieter Rams, "Ten Principles for Good Design" — the philosophy
  underlying the checklist above.
- Don Norman, *The Design of Everyday Things* — for discoverability
  and error-prevention reasoning (affordances, signifiers, mapping).
- Nielsen Norman Group's 10 usability heuristics — for the
  interaction-level checks above.
- Adam Wathan & Steve Schoger, *Refactoring UI* — for concrete visual
  hierarchy/spacing/contrast judgment calls when reviewing layout.
