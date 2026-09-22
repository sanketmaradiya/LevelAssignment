# MiniCalm

A small 2-screen meditation app built for the Level iOS assignment: a SwiftUI
library list and a UIKit + XIB player screen, wired together with MVVM.

## How to run

1. Open `LevelAssignment.xcodeproj` in Xcode 16+.
2. Select the `LevelAssignment` scheme and any iOS 16+ simulator (or device).
3. Build & run (⌘R). No third-party dependencies, no `Package.swift`/CocoaPods
   setup — it's a stock Xcode project.
4. The library list fetches live data from the assignment's gist endpoint on
   launch, so an internet connection is required to see real sessions (the
   skeleton placeholder shows regardless of connectivity).

## Architecture

**MVVM throughout**, with a thin coordinator layer for navigation:

- **Models** — `Session` (`Models/Session.swift`) decodes the API's session
  shape, and `LossyArray` (`Models/LossyArray.swift`) is a generic decoding
  wrapper that drops individually malformed array elements instead of
  failing the whole response.
- **Networking** — `SessionsAPIClient` (`Networking/SessionsAPIClient.swift`)
  fetches sessions with plain `async/await` `URLSession` (no Combine). It
  decodes a `SessionsResponse { sessions: LossyArray<Session> }` wrapper,
  since the real endpoint returns `{ "sessions": [...] }` rather than a bare
  top-level array. `NetworkError` (`Networking/NetworkError.swift`) maps
  failures to user-facing messages.
- **Library screen (SwiftUI)** — `LibraryViewModel` owns load/refresh state
  (`loading` / `loaded` / `failed`) and exposes it via `ObservableObject`.
  `LibraryView` renders a redacted/skeleton list (`.redacted(reason:
  .placeholder)` over the real row view, not a spinner) while the first
  fetch is in flight, the real list once loaded, `.refreshable` for
  pull-to-refresh, and `ErrorStateView` with a retry button if the initial
  load fails with nothing to show. `SessionRowView` renders artwork
  (`AsyncImage`), title, teacher, duration, and a premium badge.
- **Player screen (UIKit + XIB)** — `PlayerViewController.xib` defines the
  screen's view hierarchy (no storyboard, no SwiftUI). `PlayerViewModel`
  owns an `AVPlayer` and exposes state through plain closures (no Combine):
  play/pause, a seekable progress slider with elapsed/remaining time, and a
  speed button cycling `1x → 1.5x → 2x`. Speed is applied by setting
  `AVPlayer.rate` directly, which both takes effect immediately during
  playback and is remembered/reapplied on the next resume, satisfying the
  "survives pause/resume" requirement without extra state tracking.
  Background playback works via the `audio` `UIBackgroundModes` entry plus
  an `AVAudioSession` configured for `.playback`.
- **Navigation** — `AppCoordinator` (`Navigation/AppCoordinator.swift`) owns
  a single `UINavigationController`. The SwiftUI library list is embedded as
  its root via `UIHostingController`; tapping a row pushes the UIKit
  `PlayerViewController` directly onto that same navigation controller, so
  push/pop (including the back button) is native UIKit navigation rather
  than a SwiftUI/UIKit interop shim. This is the actual SwiftUI ↔ UIKit
  interop the assignment calls out, and it's exercised on every row tap and
  every back-navigation.

## Handling imperfect data

- Any session missing an `id` is dropped (via `LossyArray`); every other
  field falls back to a sensible default (e.g. `"Untitled Session"`) rather
  than failing the whole decode.
- Unparsable or `null` `artwork_url` / `audio_url` become `nil`, which the
  UI renders as a placeholder icon (artwork) or surfaces as a playback error
  alert (audio) instead of crashing.
- A player-side network/audio failure (e.g. a dead `audio_url`) shows an
  alert and leaves the play button disabled for that session; it never
  takes down the app.
- No force unwraps (`!`) anywhere in app code: `@IBOutlet`s are declared as
  plain optionals (not the usual `!` IUOs) and accessed via optional
  chaining, and the fixed endpoint URL is built with `guard let` +
  `preconditionFailure` rather than `URL(string:)!`.

## Trade-offs / what I'd do differently with more time

- `ObservableObject`/`@Published` on `LibraryViewModel` technically requires
  `import Combine`, since that's where SwiftUI defines those protocols on
  iOS 16 (no `@Observable` macro pre-iOS 17). No Combine operators or
  publishers are used anywhere — the "no Combine" constraint is honored for
  networking (`async/await` only) and for the player's closure-based state.
  I'm calling this out explicitly since it's a corner worth being transparent
  about rather than silently working around.
- The XIB lays out its controls with nested `UIStackView`s rather than a
  hand-tuned pixel layout — functional, not pixel-perfect, per the
  assignment's own priority ("least important: visual polish").
- Pull-to-refresh failures keep whatever sessions are already on screen and
  show a small inline banner, rather than wiping the list — this felt like
  better UX than the initial-load error state, but it's an interpretation
  call, not a spec requirement.
- With more time: unit tests around `LossyArray`/`Session` decoding edge
  cases and `PlayerViewModel`'s speed/seek logic, and a proper loading
  state for artwork in the player screen (currently a silent no-op on
  failure).

## AI assistance

Built with Claude Code (Anthropic) as a pair-programming assistant for the
full implementation — architecture, Swift/SwiftUI/UIKit code, the
hand-authored XIB, and debugging (including catching that the live endpoint
wraps sessions in `{ "sessions": [...] }` rather than a bare array, after
an initial run against the real API surfaced a decoding failure). All code
was reviewed and built/run-verified against the real endpoint before being
committed.
