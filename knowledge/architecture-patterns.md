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
  `@MainActor` isolation for UI-touching types.
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
