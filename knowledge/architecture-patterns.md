# iOS Architecture Patterns

Referenced by `ios-architect`. Concrete pattern/decision criteria — read
this before proposing a structure, then apply the agent's own
"When consulted" procedure on top of it.

- **Patterns:** MVVM with `@Observable` (iOS 17+) or `ObservableObject`
  (iOS 16 and earlier), Clean Architecture layering (domain/data/
  presentation) for larger apps, VIPER only when a team is already
  fluent in it. MVC is fine for genuinely simple screens — don't
  over-engineer a settings screen.
- **Swift Concurrency:** actors for shared mutable state, `Sendable`
  conformance planning, structured concurrency (`async let`, task
  groups) over unstructured `Task {}` sprinkled through view code,
  `@MainActor` isolation for UI-touching types. Enable the Swift 6
  language mode (or `-strict-concurrency=complete` under Swift 5) when
  proposing new concurrent code — it's the actual mechanical check
  behind a "thread-safe" claim; without it, isolation violations only
  surface as runtime crashes or silent races. Cancellation is part of
  the structure, not an afterthought: a `Task` that doesn't check
  `Task.isCancelled` in a loop, or that isn't cancelled when its owning
  view disappears, keeps running and can touch state after its context
  is gone — propagate cancellation the same way you'd propagate any
  other resource cleanup.
- **SwiftUI state ownership:** `@StateObject` for a reference type a
  view *creates and owns* — SwiftUI keeps it alive across that view's
  re-renders and only recreates it if the view's own identity changes.
  `@ObservedObject` for a reference type *passed in* from a parent —
  using it for an owned instance is the single most common SwiftUI
  state bug, because the parent's re-render can recreate the object
  and silently reset all its state. Get this backwards and the symptom
  looks like "my state randomly resets," not an obvious ownership error.
- **SwiftUI view identity:** two views SwiftUI considers "the same"
  (same type, same explicit `.id()`, same position in a stable
  container) persist their `@State` across a body re-evaluation;
  identity-losing changes (conditionally switching between different
  view types in the same slot, or changing a `ForEach`'s `id` source)
  reset state and can produce visible animation glitches. If a screen
  "loses" its state or animates strangely on an unrelated data change,
  check whether something upstream is changing the view's identity, not
  just its content.
- **Modularization:** local Swift Package Manager packages split by
  feature/domain boundary, not by technical layer (`Features/Profile`
  not `ViewModels/`, `Views/`, `Models/` as top-level splits). A package
  boundary should force a real dependency direction, not just organize
  files.
- **Persistence:** SwiftData for new iOS 17+-only apps with
  straightforward model graphs; Core Data when the app must support
  iOS 16 or earlier, needs CloudKit sync maturity, or already has a
  Core Data stack not worth migrating.
- **Navigation:** `NavigationStack` with typed `NavigationPath` for
  SwiftUI-first apps; coordinator pattern when a UIKit navigation stack
  is still present and needs to interoperate with SwiftUI screens.
- **Dependency injection:** initializer injection as the default;
  reserve an environment-based DI container for cross-cutting concerns
  (analytics, feature flags) that would otherwise bloat every
  initializer.
- **Security-aware structure:** a single networking layer/client so
  transport security policy (ATS, certificate/public-key pinning if the
  app uses it, auth-header injection) lives in one place instead of
  being reimplemented per call site. Credentials, tokens, and other
  secrets belong behind a Keychain-backed storage protocol — never
  `UserDefaults` or a plist — wrapped so it's swappable/mockable like
  any other dependency. Don't design view/ViewModel state that holds
  raw secrets longer than the single request that needs them; that's
  how a secret ends up in a crash report or a debug log.
