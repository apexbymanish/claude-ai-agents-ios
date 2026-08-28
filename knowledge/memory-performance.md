# Memory & Performance Knowledge

Referenced by `ios-memory-performance-engineer`. Concrete, checkable
patterns — read this when a task touches the technology in question,
rather than relying on general ARC knowledge alone.

## General ARC, Instruments, image/cache, concurrency, launch time

- **ARC retain cycles:** closures capturing `self` strongly inside
  properties that outlive the call (completion handlers stored on
  `self`, `Timer` targets, `NotificationCenter` observers without
  `[weak self]`), delegate properties declared `strong`/non-`weak`
  where the delegate is a parent that owns the child, and reference
  cycles between two objects holding strong references to each other.
- **`weak` vs `unowned` judgment:** `weak` when the referenced object
  can legitimately become nil during the reference's lifetime (most
  delegate/callback cases); `unowned` only when the reference's lifetime
  is provably tied to the owner's (e.g. a child that cannot outlive its
  parent) — misusing `unowned` trades a leak for a crash, which is
  worse, so default to `weak` when unsure.
- **Instruments workflow (describe for the human to run):**
  1. Leaks instrument to catch actual cycles — look for objects whose
     count only grows across repeated navigation in/out of a screen.
  2. Allocations instrument with "Mark Generation" before/after
     repeating an action (e.g. push/pop a screen 10 times) — any
     persistent growth after garbage generations settle indicates a
     leak even without an explicit "Leaked" flag.
  3. Time Profiler for CPU-bound slowness (scrolling jank, slow launch)
     — look for unexpectedly hot frames in view layout/body evaluation.
- **Image and cache memory:** decode/downsample images to their display
  size before caching (`UIGraphicsImageRenderer` or
  `ImageIO`-based downsampling) rather than caching full-resolution
  decoded bitmaps; bound `NSCache` with `countLimit`/`totalCostLimit`
  rather than leaving it unbounded.
- **`autoreleasepool` in tight processing loops:** decoding, resizing,
  or otherwise processing many images (or other autoreleased objects)
  in a loop without an explicit `autoreleasepool { }` around each
  iteration lets every iteration's temporary objects accumulate until
  the *outer* run loop drains — on a tight loop with no run-loop
  iteration in between, that's effectively "accumulate until the whole
  loop finishes," producing a sharp memory spike proportional to the
  batch size rather than the size of one item. Wrap each iteration's
  work in its own `autoreleasepool` when processing a batch, not just
  when the total is expected to be large.
- **Swift Concurrency:** unnecessary actor hops cost real time — don't
  mark a type `@MainActor` wholesale if only its UI-facing methods need
  it; watch for accidental data races on non-`Sendable` types crossing
  actor boundaries, which the compiler will only catch in strict
  concurrency mode.
- **Launch time:** anything doing synchronous work in
  `application(_:didFinishLaunchingWithOptions:)` or a SwiftUI `App`
  init (network calls, heavy disk reads, synchronous SDK setup) directly
  extends time-to-first-frame — defer it past first render when possible.

## Framework & library-specific patterns

These are exactly the places production iOS apps develop non-obvious
memory and lifecycle problems:

- **RxSwift:** a `DisposeBag` must be owned by the object whose
  lifetime should bound the subscription (usually the view/ViewModel) —
  a shared or static `DisposeBag` never disposes and leaks every
  subscription added to it for the app's lifetime. `.subscribe(onNext:
  { ... })` closures capturing `self` need `[weak self]` exactly like
  any other closure. `.share()`/`.replay()` can keep buffered values
  and subscribers alive longer than the call site suggests.
- **WKWebView:** each instance is expensive (backed by its own process)
  — don't create one per cell or per navigation without reuse.
  `WKUserContentController.add(_:name:)` retains its handler strongly;
  call `removeScriptMessageHandler(forName:)` before the owning view
  deallocates or the handler (and whatever it captures) leaks.
  `evaluateJavaScript` completion closures capturing `self` follow the
  same rule as any other closure.
- **PDFKit:** `PDFDocument` can pull an entire large file into memory —
  render pages on demand (`PDFPage.thumbnail(of:for:)`) instead of
  rasterizing every page upfront. A `PDFView` holds the document plus
  its own rendered-page cache; don't duplicate that cache elsewhere.
- **Core Data:** large fetches without `fetchBatchSize` or a
  `fetchLimit` pull far more into memory than the screen needs. Holding
  strong references to many `NSManagedObject`s defeats Core Data's
  faulting model — let objects fault back out when not actively
  displayed. `NSFetchedResultsController` delegates need the same
  `weak` discipline as any other delegate.
- **Firebase (Firestore/RTDB/Auth):** `addSnapshotListener`/
  `observe(_:with:)` listeners that are never removed
  (`ListenerRegistration.remove()` / `removeObserver`) leak for the
  app's lifetime, not just the screen's. Registering an auth-state
  listener more than once without removing the prior one duplicates
  callbacks and their captured state.
- **CocoaPods:** not a leak source itself, but watch for multiple pods
  bundling their own copy of the same underlying library (e.g. two
  different networking stacks), inflating both binary size and runtime
  memory footprint without either being fully removable independently.
- **Keychain:** `SecItemCopyMatching` in a hot path (called every
  scroll frame or on every keystroke) is needlessly expensive — read
  once and cache the value in memory for the session rather than
  re-querying the Keychain repeatedly.
- **Third-party presentation libraries (e.g. PanModal):** delegate-based
  presentation APIs are a common source of retain cycles when the
  library's delegate property isn't `weak` on the integrating side —
  verify the presented view controller actually deallocates after
  dismissal, not just that it visually disappears.
- **UICollectionView / UITableView:** an async image-load completion
  must check the cell is still showing the same index path before
  applying the result — a stale completion firing after reuse both
  shows the wrong image (correctness bug) and keeps the old image data
  alive via the closure capture longer than necessary.
  `UICollectionViewDataSourcePrefetching` requests for cells scrolled
  away should be cancelled, not left to complete and discard their result.
- **SwiftUI/UIKit bridges:** a `UIViewRepresentable`/
  `UIViewControllerRepresentable`'s `Coordinator` capturing `self`/the
  parent strongly, combined with the represented UIKit view holding a
  strong reference back to the coordinator, is a cycle — verify the
  coordinator doesn't outlive the SwiftUI view unexpectedly. A
  `UIHostingController` embedded in UIKit needs the standard
  `willMove(toParent: nil)` + `removeFromParent()` sequence or it (and
  its whole SwiftUI view tree) stays alive after removal from the
  screen.
- **AVFoundation:** KVO observers on `AVPlayer`/`AVPlayerItem` not
  removed before deinit is a classic pattern that causes a crash, not
  just a leak — always pair `addObserver` with `removeObserver` on
  teardown. An `AVCaptureSession` left running after its screen is
  dismissed keeps camera hardware and buffers alive and drains battery.
- **CoreLocation:** calling `stopUpdatingLocation()` when the screen
  needing updates is dismissed matters as much as setting the delegate
  `weak` — location updates left running keep the delegate's owner
  alive via the callback and drain battery in the background.
- **URLSession:** creating a new `URLSession` per request instead of
  reusing one configured session duplicates connection-pool and cache
  overhead. Uncancelled `URLSessionTask`s keep their completion
  closure — and anything it captures — alive until the network call
  actually finishes; cancel in-flight tasks when their initiating
  screen is dismissed. A custom `URLSessionDelegate` should not itself
  capture a view controller with no path to release it before the
  session is invalidated.
