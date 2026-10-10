# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Taskchamp is a native iOS (17+) SwiftUI client for [Taskwarrior](https://taskwarrior.org/) 3.x. It embeds the Rust `taskchampion` library through a Swift bridge and syncs with the same backends Taskwarrior does (taskchampion-sync-server, S3, or GCP; the upstream iCloud Drive option is disabled in this fork). The project is generated with Tuist; there is no checked-in `.xcodeproj`.

## Toolchain and commands

Prereqs: `brew install swiftlint swiftformat mise`, Rust via rustup, then `mise install` (pins Tuist 4.84.2 from `.mise.toml`). All Tuist commands go through `mise exec -- tuist ...`; the `makefile` wraps them.

```sh
make up          # cargo-build the vendored Rust bridge, tuist install, tuist generate (opens Xcode)
make generate    # regenerate the Xcode project after editing Project.swift or Tuist/Package.swift
make build       # tuist build
make lint        # swiftlint over the Sources of taskchamp, taskchampWidget, taskchampShared, taskchampShareExtension
make format      # swiftformat over the same four source roots
make edit        # tuist edit (edit Project.swift with autocomplete)
```

Tests (target `taskchampTests`, sources in `taskchamp/Tests/`; currently unit tests for `FilterParser`, `FilterDate` and `TCFilter.compactTitle`):

```sh
make test
# single test
mise exec -- tuist test taskchamp --test-targets taskchampTests/TaskchampTests/test_endAfter_matchesRecentlyCompleted
```

Simulator build without opening Xcode (verified with Xcode 27; pick any id from `xcrun simctl list devices available`):

```sh
mise exec -- tuist generate --no-open
xcodebuild -workspace taskchamp.xcworkspace -scheme taskchamp -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' build
```

Notes:
- Xcode 27 rejects iOS deployment targets below 15. `Tuist/Package.swift` uses `PackageSettings.targetSettings` to force iOS 17 on package targets that declare older platforms (Taskchampion, cmark-gfm, NetworkImage, MarkdownUI). If a new dependency fails with "deployment target ... is set to 12.0", add it there and regenerate.
- `scripts/pre_build_script.sh` runs as an Xcode pre-build phase and runs SwiftLint (warnings only) on every build. Run `make format && make lint` before committing.
- Style is enforced by `.swiftlint.yml` (opt-in `force_unwrapping`, `implicitly_unwrapped_optional`, `trailing_closure`, `strict_fileprivate`, function body ≤ 60 lines warning) and `.swiftformat` (4-space indent, max width 120, arguments/parameters/collections wrap `before-first`, `--commas inline`, `--stripunusedargs always`).

### The Rust dependency

`Taskchampion` is a local Swift package at `task-champion-swift/taskchampion-swift/taskchampion-swift/`. The whole bridge is vendored into this repo (originally `marriagav/task-champion-swift` at commit 91af945, no history kept); the Rust crate is `task-champion-swift/taskchampion-swift/` with the bridge definitions in `src/lib.rs`. `taskchampion` is pinned to `=3.1.0` in its `Cargo.toml` to match the Taskwarrior 3.5 used alongside this app. Build outputs (`target/`, `*.a`, `generated/`) are gitignored, so a fresh clone must run `make build_taskchampion` (or `make up`) before Xcode can link. `scripts/build_taskchampion_swift.sh` cargo-builds it for `aarch64-apple-ios` (release) and `aarch64-apple-ios-sim` (debug), then copies the static libs, headers, and swift-bridge generated Swift into `RustXcframework.xcframework`. `Project.swift` sets `SWIFT_OBJC_INTEROP_MODE=objcxx` for this bridge. Anything the Swift side needs from taskchampion that isn't already exposed (e.g. a new `Replica` method) is added in `src/lib.rs`, then `make build_taskchampion` regenerates the Swift bindings; commit the regenerated headers and `Sources/Taskchampion/*.swift` together with the Rust change.

## Repo status

This is a personal fork for personal use; it does not track upstream and has no CI or App Store release tooling (fastlane, Xcode Cloud scripts, and StoreKit/paywall code were removed). The marketing version (`CFBundleShortVersionString`) is hardcoded in `Project.swift` three times (app, widget, share extension). Bump all three together.

## Architecture

### Targets (all defined in `Project.swift`)

| Target | Product | Role |
|---|---|---|
| `taskchampShared` | static framework | Models, services, utilities. Depends on `Taskchampion` (Rust) and `SoulverCore`. Everything the extensions need lives here. |
| `taskchamp` | app | SwiftUI views, App Intents/Shortcuts, navigation. Depends on `MarkdownUI`. |
| `taskchampWidget` | app extension | Home/lock-screen widgets + widget intents (complete task, quick add). |
| `taskchampShareExtension` | app extension | Share-sheet "quick add" from text/URLs. |
| `taskchampTests` | unit tests | |

All three executables share the app group `group.com.slzatz.taskchamp`, which is how they open the same task database and UserDefaults. Bundle IDs are under `com.slzatz.taskchamp` and the home-screen name is "Taskchamp Dev" so this build installs alongside the App Store Taskchamp (`com.mav.taskchamp`). Signing is automatic with the team set by `developmentTeam` at the top of `Project.swift`. There is no iCloud entitlement: `ICloudSyncService` and its settings view still exist but `.local` is filtered out of the sync picker in `SyncServiceView`.

### Data flow: one Replica, wrapped by one singleton

`TaskchampionService.shared` (`taskchampShared/Sources/Services/TaskchampionService.swift`) owns the main `Replica` (Rust object), which is only used on the main actor. Every entry point (app `ContentView.task`, widget `Provider.getTasks`, each `AppIntent.perform`) must call `setDbUrl(path:)` first; it is idempotent for the same path.

- Reads (`getTasks`, `getPendingTasks`, `getTask`, `getAllProjects`) are `@MainActor` because Rust `TaskRef` handles are not Sendable. `TCTask(from: TaskRef)` copies everything into a plain Swift struct immediately.
- Writes (`createTask`, `updateTask`, `startTask`, `stopTask`, status toggles) call `replica.sync_no_server()` right after mutating to rebuild the working set, then kick off a detached `sync()` unless `skipSync: true`. `sync()` cancels any in-flight sync task, sets `needToSync` on failure, and reloads widget timelines.
- Syncs never touch the main `Replica`. The Rust `Replica` is not thread-safe, so `SyncReplicaStore` (`taskchampShared/Sources/Services/SyncReplicaStore.swift`) opens a second `Replica` on the same database and uses it only on one serial queue, which also keeps syncs from overlapping. The two SQLite connections coordinate through WAL mode, like the app, widget, and desktop Taskwarrior do. A main-actor write made during a network sync waits on SQLite's busy timeout (about 5 s) for the sync's write transaction to finish. Never pass the main `Replica` to a background queue.
- Rust strings go in via `.intoRustString()`; tags via `RustVec<Tag>`. `updateTask` never passes annotations, because the bridge's `update_task` adds every one it is given, so saves used to pile up duplicates. The one annotation the app writes goes through `annotate_task`, which skips an exact duplicate.

### Where the database lives

`FileService.getDestinationPathForLocalReplica()` picks the directory by the selected sync type:
- `.local` (iCloud Sync, hidden in this fork): the ubiquity container's `Documents/taskchamp`.
- Everything else: `<app group container>/taskchamp`.

Switching sync type therefore switches which sqlite file is opened.

### Sync backends

`SyncServiceProtocol` (`taskchampShared/Sources/Services/SyncServiceProtocol.swift`) is implemented by static-only classes `NoSyncService`, `ICloudSyncService`, `RemoteSyncService`, `GcpSyncService`, `AwsSyncService`. Each reads its config from `UserDefaultsManager.shared`, reports `isAvailable()`, and implements a blocking `sync(replica:)` that calls the matching `replica.sync_*`. `TaskchampionService.sync` runs it on the sync queue with the sync replica. Services are `final` and the protocol is `Sendable`, so keep them stateless. `TaskchampionService.SyncType` + `getSyncServiceFromType` is the registry. Adding a backend means: a `SyncType` case, a service class, new `TCUserDefaults` keys, a settings view under `taskchamp/Sources/View/SyncService/`, and a README section.

### Persistence besides the replica

- `UserDefaultsManager` (`taskchampShared/Sources/Utilities/UserDefaults.swift`): `.shared` is the app-group suite (visible to widget/share extension); `.standard` is app-only. All keys are the `TCUserDefaults` enum. Saved filters are stored twice: in SwiftData for the app UI and as JSON under `.savedFilters` so widgets/intents can read them without SwiftData.
- SwiftData `ModelContainer(for: TCFilter.self, TCTag.self)` is created by each host (`TaskchampApp.init`, `ShareViewController.viewDidLoad`) and handed to `SwiftDataService.shared.container`. `TCTag.tagFactory` dedupes tags against SwiftData and feeds the `NLPService` autocomplete cache.

### Filtering and tags

- `TCFilter.fullDescription` is a Taskwarrior-style filter string (`+tag -tag project:x prio:H status:pending recur end.after:now-1wk`, with `or` and parentheses). `FilterParser` in `FilterExpression.swift` tokenizes it into a `FilterExpression` tree; `TCTask.taskFactory(from:withFilter:)` applies it. The default "My tasks" filter short-circuits to `replica.pending_tasks()`.
- Words the tokenizer doesn't recognize produce no token. `FilterParser.unrecognizedTerms(in:)` reports them, and `AddFilterView` refuses to save a filter that has any. Adding a filter term means: a `FilterToken` case, a branch in `FilterParser.token(for:)`, a `FilterExpression` case (`matches`, `compactDescription`, `parseAtom`), and a case in `NLPService.setLegacyProperties` (that switch is exhaustive).
- Date comparisons (`<attr>.after|before|above|below:<value>`) live in `FilterDate.swift`: `FilterDateAttribute` maps attribute names to `TCTask` date fields, and `FilterDate` parses Taskwarrior date values (`now`, `today`, `sow`, ISO dates, `now-1wk`). Relative values are resolved inside `matches(_:now:)`, so saved filters keep rolling. Supporting a new date attribute requires the value on `TCTask`, which may need a new `get_*` in the Rust bridge (`get_end`/`get_entry` were added for this).
- Recurring template tasks (`status == recurring`) are hidden unless the filter explicitly asks for `status:recurring`.
- `TCSyntheticTag` (OVERDUE, DUE, TODAY, WEEK, LATEST, …) mirrors Taskwarrior's virtual tags and is computed in Swift inside `TCTask.init(from:)`; these are all-caps ASCII and are hidden from tag suggestions.
- `NLPService` provides autocomplete for `prio:`/`project:`/`status:`/`+`/`-` surfaces and uses SoulverCore for natural-language due dates in the create-task field.

### Cross-target entry points

- Deep links use the `taskchamp://` scheme, handled in `ContentView.handleDeepLink`: `task/<uuid>`, `task/new?content=…` (also falls back to `.pendingNewTaskContent` in UserDefaults), and `filter/<uuid|default>`. Widgets, notifications, and Shortcuts all route through these; notification taps arrive via `.TCTappedDeepLinkNotification`.
- `FilterAppEntity.swift` is duplicated verbatim in `taskchamp/Sources/Intents/` and `taskchampWidget/Sources/Intents/` because App Intents entities must compile into each extension. Edit both. The shared helpers (`getFilterFromUserDefaults`, `getSavedFiltersFromUserDefaults`) live in `taskchampShared/Sources/Models/FilterAppEntity.swift`.
- Task notes live in vimango (the upstream Obsidian integration was removed). The note button in `EditTaskView` opens `vimango://task-note?uuid=…&title=…&project=…` in VimNotes (`~/vimango_ios`), which finds the note by a `taskwarrior: <uuid>` frontmatter line, or creates it. Once iOS reports that the URL opened, `TaskchampionService.linkVimangoNote` adds a `vimango` annotation, which only sets `TCTask.hasNote` and the button label. Rows in the task list whose task has a note show a note button (`TaskCellView`'s `openNote`) that sends the same URL (`TCTask.vimangoNoteURL`), so an existing note opens without the edit screen. Old `task-note:` annotations are ignored.
- The app registers the URL scheme `taskchampdev` (in `Project.swift`) for links from other apps, such as the note's "Open task" link. It doesn't register `taskchamp`, because the App Store Taskchamp claims it; `taskchamp://` still works for the app's own widgets and notifications. `handleDeepLink` accepts both.

### Misc conventions

- Navigation is a `NavigationPath` held by `PathStore`, with `GlobalState` (`isSyncingTasks`, `replicaReady`) injected via `.environment`. `PathStore` can restore a saved path in `init`, but nothing calls its `save()`, so in practice the path is never saved and every launch starts at the task list.
- `TCTask`'s `Codable` round-trips every field the task screen reads (uuid, dates, tags, the vimango note annotation), with tests in `TaskchampTests`, so wiring up `PathStore.save()` (e.g. on `scenePhase` going to background) is enough to restore an open task. If you do, have `EditTaskView` re-read the task by uuid when it appears: the restored value is a snapshot from disk, and saving from it could overwrite changes synced from the Mac since.
- Views are split as `FooView.swift` + `FooView-Ext.swift` (extension holding actions/helpers) to stay under the lint body-length limits.
- The app icon (white "T" on green) is the same design as the macOS Taskwarrior app's. `scripts/make-icon.swift` draws the committed `AppIcon.appiconset/AppIcon.png` and is run by hand (`swift scripts/make-icon.swift`). It is a twin of `~/taskwarrior_macos/Scripts/make-icon.swift`, so a design change belongs in both. The iOS version is opaque and full-bleed because iOS applies its own mask. The extensions use the host app's icon.
