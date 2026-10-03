# Taskchamp Dev — UI plan, round 1

## Context

The fork now runs on the user's iPhone as "Taskchamp Dev" (bundle `com.slzatz.taskchamp`) next to the App Store Taskchamp, both syncing to the user's taskchampion-sync-server. The user wants UI/UX improvements for personal use. This first round covers three items the user raised on 2026-09-27:

1. The dev and App Store apps look identical once open; the main screen needs a dev marker.
2. A selected filter becomes the huge large-title (`status:pending prio:H project:work`), of which ~20 characters are visible. It should be a compact summary like `pending H work`.
3. Task rows are too loose; they should be tighter and look like the user's vimango iOS app.

More UI changes will follow in later rounds. Work on `dev`, one commit per item; the user pushes (never `git push`).

This plan was written in one session and is meant to be implemented in a later one. This file (`docs/ui-plan.md`) is the canonical copy: update it as items are completed or the design changes, and mark finished items as done.

## Current code (read before changing)

- `taskchamp/Sources/View/TaskListView.swift`: main screen. Title is `.navigationTitle(...)` at the bottom of `body`, showing `selectedFilter.displayName`, `"Select Tasks"`/`"N Selected"` in edit mode, or `""` when empty with the default filter. Large-title display mode (the default). The `.principal` toolbar slot currently holds only the "Syncing..." spinner (`loadingView()`). The list is `.listStyle(.inset)` with `.listRowBackground(Color.clear)`.
- `taskchamp/Sources/View/TaskListView-Ext.swift`: `favoriteFiltersMenu` (also shows `filter.displayName`), `selectFilter`.
- `taskchampShared/Sources/Models/TCFilter.swift`: `displayName` is `name` if set, else `fullDescription`. `filterExpression` is `FilterParser.parse(fullDescription)`. `isDefaultFilter` and `defaultFilter` ("My tasks").
- `taskchampShared/Sources/Models/FilterExpression.swift`: `FilterExpression` enum (`and`, `or`, `tag`, `notTag`, `project`, `priority`, `status`, `recur`) and the `FilterParser` tokenizer and recursive-descent parser.
- `taskchamp/Sources/View/Cells/TaskCellView.swift`: row is a two-line `VStack`. Line 1 is the description (line limit from the `taskCellLineLimit` user setting, 1–5, default 2) plus the project in italic subheadline on the right. Line 2 is the due date, an active icon, recurrence, and the colored priority letter. There is `.padding(.vertical, 3)` on line 1.
- `Project.swift`: targets and base settings (Tuist; run `make generate_no_open` after edits).

## 1. DEV badge on the main screen — DONE (2026-09-27)

User choice: a small colored "DEV" capsule in the nav bar. No accent-color or icon change.

- Add a compile flag to the `taskchamp` app target only, in `Project.swift` target settings: `"SWIFT_ACTIVE_COMPILATION_CONDITIONS": "$(inherited) TASKCHAMP_DEV"`. Keep `$(inherited)` so `DEBUG` survives. Removing this one line later turns the badge off.
- New small view `taskchamp/Sources/View/Components/DevBadge.swift`: `Text("DEV")`, caption2 bold, white on orange (or red) `Capsule`, compact padding. Body wrapped in `#if TASKCHAMP_DEV … #endif` so it renders nothing otherwise.
- Place it in the header built in item 2, so badge, title, and sync spinner share the `.principal` slot.

## 2. Compact filter title — DONE (2026-09-27)

Implemented as written, plus: `prio:None` summarizes as `no prio`; `make test` previously ran nothing because the `taskchamp` scheme had no test action, so `Project.swift` now adds `testAction: .targets(["taskchampTests"])`. `ContentView`'s `largeTitleTextAttributes` was left in place.

**Summary logic (shared, testable)**

- In `FilterExpression.swift`, add `public var compactDescription: String` on `FilterExpression`:
  - `.status(s)` → `s.rawValue` (`pending`)
  - `.priority(p)` → `p.rawValue` (`H`/`M`/`L`)
  - `.project(x)` → `x`
  - `.tag(x)` → `+x`
  - `.notTag(x)` → `-x`
  - `.recur` → `recur`
  - `.and` → operands joined with spaces
  - `.or` → operands joined with `" | "`, wrapped in parentheses when nested inside an `.and`
- In `TCFilter.swift`, add `public var compactTitle: String`:
  - non-empty `name` → `name` (user-named filters keep their name)
  - `isDefaultFilter` → `"My tasks"`
  - `filterExpression?.compactDescription` if it parses
  - otherwise `fullDescription`
- Example: `status:pending prio:H project:work` → `pending H work`.
- Related fix in `FilterParser.tokenize`: also accept `priority:` as an alias of `prio:`. Taskwarrior users type `priority:H`, and today that word is silently dropped, so the filter matches everything.

**Header layout**

- In `TaskListView`, add `.navigationBarTitleDisplayMode(.inline)`, so there's no giant title and no shrink-on-scroll jump.
- Replace the `.principal` `ToolbarItemGroup` contents with an `HStack(spacing: 6)` containing:
  - `DevBadge()`
  - `Text(headerTitle)` with `.font(.headline)`, `.lineLimit(1)`, `.truncationMode(.tail)`
  - `ProgressView()` (small) when `globalState.isSyncingTasks`, replacing the old "Syncing..." text
- `headerTitle`, computed in `TaskListView-Ext.swift`, keeps the existing rules (edit-mode "Select Tasks"/"N Selected"; empty-plus-default gives an empty title) but uses `selectedFilter.compactTitle` instead of `displayName`.
- Keep `.navigationTitle(headerTitle)`. It's hidden behind the principal item but still supplies the back-button label in `EditTaskView`.
- Use `compactTitle` in `favoriteFiltersMenu` too, for consistency.
- Remove the now-unneeded `largeTitleTextAttributes` line in `TaskListView.init`. Leave the one in `ContentView` unless it's also unused.

**Tests**

- Replace the placeholder in `taskchamp/Tests/TaskchampTests.swift` with cases for `compactDescription` and `compactTitle`: the example above, tags, an `or` group, a named filter, the default filter, an unparseable string, and the `priority:` alias.
- Use `@testable import taskchampShared`. If that import fails in the test target, add `taskchampShared` to its dependencies in `Project.swift`.

## 3. Tighter rows, styled after vimango iOS — DONE (2026-09-27)

Implemented with the user's choices: tag badges shown (user tags only, synthetic ones filtered out); line limit defaults to 1. After comparing screenshots the user kept the edge-to-edge `.listStyle(.inset)` list rather than vimango's card, and asked for rows tighter than vimango's: `.listRowInsets` top/bottom 2 (leading/trailing 16), which fits ~13 rows instead of ~9. Due dates render compactly in the row ("Today", "Tomorrow", "Oct 1"; year only if not this year, time only if not midnight) instead of `localDate`. `TagBadge` lives in `taskchamp/Sources/View/Components/TagBadge.swift`.

**Reference:** the vimango iOS app is cloned at `~/vimango_ios`. The row is `VimNotes/VimNotes/Views/NoteRowView.swift` and the list is `VimNotes/VimNotes/Views/NoteListView.swift`. Re-read both before starting. The vimango row design, as of 2026-09-27:

- `VStack(alignment: .leading, spacing: 4)`, whole row `.padding(.vertical, 4)`.
- **Line 1:** the title in `.font(.headline)` with `.lineLimit(1)`, then small `.caption` SF Symbol indicators (yellow `star.fill`, secondary `photo`), then `Spacer()`.
- **Line 2:** `HStack(spacing: 6)` with two badges, then `Spacer()`, then the date in `.caption2` `.secondary`.
- **Badge helper:** `Text` in `.caption`, `.secondary` foreground, padding 6 horizontal and 2 vertical, background `color.opacity(0.12)`, `cornerRadius(4)`. Context is blue and folder is green.
- **Deleted rows** are `.strikethrough` plus `.opacity(0.45)`.
- **List:** a plain `List` with no `.listStyle`, row insets, or row-background overrides. `NavigationLink(value:)` rows with leading and trailing swipe actions. The header is a standard `navigationTitle`.

**Proposed mapping to `TaskCellView`.** Confirm it with the user in a few bullets before implementing, since it decides what information rows show.

- **Line 1:** the description in `.headline`. Keep the `taskCellLineLimit` setting, but consider defaulting it to 1 to match vimango. Add caption indicators for active (`play.fill`, accent) and recurring (`repeat`, secondary).
- **Line 2:** a project badge (blue), a priority badge colored by level (red for H, orange for M, green for L), and optionally tag badges in green, which the current row doesn't show. Then `Spacer()`, then the due date in `.caption2`. Make an overdue date red. Omit line 2 entirely when a task has no project, priority, tags, or due date.
- **Completed and deleted tasks:** `.opacity(0.45)`, replacing the current secondary and red coloring. Only deleted rows get a strikethrough, in red. Completed rows are grayed only, because a strikethrough made them hard to read (changed 2026-10-03 at the user's request).
- **Spacing:** use vimango's `spacing: 4` and `padding(.vertical, 4)`, and remove the current per-line `.padding(.vertical, 3)`.
- **List:** remove `.listRowBackground(Color.clear)` and `.listStyle(.inset)` from `TaskListView` only if the result looks closer to vimango. Compare screenshots of both.
- **Keep intact:** swipe actions, edit-mode multi-select, and the search filter.
- Put the badge helper in its own small view, e.g. `taskchamp/Sources/View/Components/TagBadge.swift`, so the edit screen can reuse it later.

## Verification

- **Build:** `make generate_no_open`, then the simulator build from `CLAUDE.md` (xcodebuild with `-destination 'platform=iOS Simulator,name=iPhone 18 Pro'`). Aim for no new warnings. SwiftLint isn't installed; run `make lint` only if the user installs it.
- **Tests:** run `make test`; the new filter-summary tests must pass.
- **Simulator sync (2026-09-27):** after the bundle-ID change, writing the sync prefs from `~/.taskrc` gave `error while unsealing encrypted value` on sync, so the encryption secret written was wrong (maybe quoting in `.taskrc`). The user re-entered it in the app's Sync Settings and sync works.
- **Visual check in the simulator:** the simulator app is now `com.slzatz.taskchamp` with app group `group.com.slzatz.taskchamp`, so its sync settings are gone. Reconfigure it the way the `sync-setup` memory describes: write `remoteServerUrl`, `remoteServerClientId`, `remoteServerEncryptionSecret`, and `selectedSyncType` (JSON `{"remote":{}}` as data) into the app-group preferences via `xcrun simctl spawn booted defaults write <group container>/Library/Preferences/group.com.slzatz.taskchamp …`, with the app terminated. Get the container path from `xcrun simctl get_app_container booted com.slzatz.taskchamp group.com.slzatz.taskchamp`. Never print the secret. Then take screenshots with `xcrun simctl io booted screenshot` of:
  - the default list, where the DEV badge plus "My tasks" appears in a compact inline header
  - a filter such as `status:pending prio:H project:work`, whose header should read `pending H work`
  - edit mode, whose header should read "Select Tasks"
  - a scrolled list, where the header shouldn't jump
  - the rows next to vimango
- **Remember the simulator writes to real task data:** use throwaway test tasks.
- **Phone:** the user installs with Cmd-R on their iPhone and confirms. Commit each item to `dev` after it's verified. The user pushes.

# Round 2 — faster filter switching (2026-09-27)

1. **Header title is a filter dropdown — implemented, awaiting on-device check.** Outside edit mode, the principal header's title is a `Menu` (`filterSwitcherMenu` in `TaskListView-Ext.swift`) showing the compact title plus a chevron. The menu lists "My tasks", then every saved filter (favorites first, in `order`), each with a checkmark when selected, then "Manage Filters" to open `AddFilterView`. In edit mode, the header is still plain text.
2. **Save button on the filter screen — implemented, awaiting on-device check.** `AddFilterView`'s command-line row has an inline "Save" button (`addFilter()`, the same action as Return), disabled while the field is empty.
3. Note: the Projects section on the filter screen came from upstream commit fd50b68 (2026-06-13, merged to upstream dev via PR #131). Upstream's release branch stops at 2026-05-23, so the App Store build doesn't have it.
