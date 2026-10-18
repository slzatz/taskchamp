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

1. **Header title is a filter dropdown — DONE, confirmed on the phone.** Outside edit mode, the principal header's title is a `Menu` (`filterSwitcherMenu` in `TaskListView-Ext.swift`) showing the compact title plus a chevron. The menu lists "My tasks", then every saved filter (favorites first, in `order`), each with a checkmark when selected, then "Manage Filters" to open `AddFilterView`. In edit mode, the header is still plain text.
2. **Save button on the filter screen — DONE, confirmed on the phone.** `AddFilterView`'s command-line row has an inline "Save" button (`addFilter()`, the same action as Return), disabled while the field is empty.
3. Note: the Projects section on the filter screen came from upstream commit fd50b68 (2026-06-13, merged to upstream dev via PR #131). Upstream's release branch stops at 2026-05-23, so the App Store build doesn't have it.

# Round 3 — note icon in task rows (2026-10-09)

**DONE (2026-10-09), confirmed on the phone.** A row whose task has a vimango note (`TCTask.hasNote`, from the `vimango:` annotation) shows a `doc.text` button in the accent color at the right end of line 1, above the due date. Tapping it opens the note in VimNotes, and tapping anywhere else in the row still opens the edit screen (`.buttonStyle(.borderless)` keeps the button's tap separate from the `NavigationLink`). The button is hidden in multi-select mode. Rows without a note are unchanged: notes are still created from the edit screen, which adds the annotation.

- `TCTask.vimangoNoteURL` (`taskchampShared/Sources/Models/TCTask-Vimango.swift`) builds the `vimango://task-note` URL for both the row and `EditTaskView`.
- `TaskCellView(task:openNote:)` draws the button; `TaskListView.openNote(_:)` opens the URL and shows "Can't open VimNotes" if that fails.
- Confirmed on the phone: the icon opens the right note, and the tap area (16 pt to its left, a little above and below) is big enough that misses into the edit screen haven't been a problem.

# Round 4 — one-line rows, filter-aware badges, title size (planned 2026-10-18)

**Status: all three items implemented 2026-10-18 (item 2's edit mode, taps and swipes, and item 3's menus, still to be checked on the phone); the user's decisions are recorded under "Decisions" at the end.** Written at the end of a VimNotes session (`~/vimango_ios`) that made the same changes to its note list, so these steps reuse what that work turned up. Work on `dev`, one commit per item; the user pushes.

The user's request:

1. Don't show what the filter already says. When the selected filter can only match one project, every row's project badge repeats it.
2. Use one line per task instead of two.
3. Let the user change the title size, as VimNotes now does.

## Reference: what VimNotes did

Re-read before starting: `~/vimango_ios/VimNotes/VimNotes/Views/NoteRowView.swift` and `NoteListView.swift`, plus the "List view: filters and row indicators" section of `~/vimango_ios/CLAUDE.md`. Commits `1ae44bf` (one-line rows, badges only where the filters leave a choice) and `1dbb706` (title sizes, remembered settings).

- **Row:** one `HStack(spacing: 6)`: the title (`.lineLimit(1)`), the star, `Spacer(minLength: 8)`, then an inner `HStack(spacing: 4)` with `.layoutPriority(1)` holding the badges, fixed icon slots and the date. The trailing group is laid out first, so the title is what gets cut short.
- **Badges** cap themselves with `.lineLimit(1).frame(maxWidth: 90).fixedSize()`, applied before the padding and background. This keeps each badge at its own width up to the cap. A plain `.frame(maxWidth:)` stretches every badge to the cap.
- **Icon slots** are always drawn, at `.opacity(0)` plus `.accessibilityHidden` when absent, so icons sit in the same column on every row.
- **Date column:** a `ZStack(alignment: .trailing)` over a hidden `Text("Yesterday")` gives a fixed width, so dates line up. Dates from earlier years print as `9/30/24` to fit that width.
- **Row height:** iOS 26 pads every List row to about 52pt. The one-line rows only got shorter after `.environment(\.defaultMinListRowHeight, 1)` on the `List`; with padding 7 they're about 36pt. Check whether taskchamp's rows are being padded up the same way.
- **Chevron:** `.navigationLinkIndicatorVisibility(.hidden)` removes the `>` and gives its width back to the title. It is `@available(iOS 17.0, *)` in the Xcode 27 SDK (checked 2026-10-18), so it works at taskchamp's 17.0 deployment target.
- **Title size:** `enum ListTitleSize: Int` with small/medium/large = 14/16/18pt, stored in `@AppStorage` and offered as a "Title Size" submenu (`Picker`, `.pickerStyle(.menu)`). The font is `.system(size: size.points * scale)`, where `@ScaledMetric(relativeTo: .subheadline) var scale: CGFloat = 1` makes it follow the iOS text-size setting as well. A bare `.system(size: 14)` ignores that setting, as taskchamp's does today. Only the title scales; padding and badges stay the same, so rows grow with the title.
- **The user's verdict:** rows of about 36pt are easy to swipe, tap and long-press on the phone. With nothing filtered, titles get the least room (about 110pt beside two badges), which the user accepted.

## Current taskchamp code (read before changing)

- `taskchamp/Sources/View/Cells/TaskCellView.swift`: two lines.
  - **Line 1:** the description (`.system(size: 14)`, `lineLimit` from the `taskCellLineLimit` setting, 1–5, default 1), the active and recurring icons, `Spacer`, and the note button (`.borderless`, with an enlarged tap area).
  - **Line 2** (only when `hasDetails`): the project badge (blue), the priority badge (tinted by level), a badge for every user tag (green), `Spacer`, and the due date (red when overdue; the time is appended when it isn't midnight).
- `TaskListView.swift`: `List(selection:)` with edit-mode multi-select, `NavigationLink(value: task)` rows, row insets 2/16/2/16, `.listStyle(.inset)`. The ellipsis Options menu holds the "Sort by" submenu and Clear filters. The header is the filter switcher `Menu` from Round 2.
- `selectedFilter` (`ContentView`) and `sortType` are **already remembered** in `UserDefaults` (`.selectedFilter`, `.sortType`). Unlike VimNotes, only the title size is new to remember.
- `FilterExpression.matches`: `.project(x)` is an exact match (`task.project == name`), not Taskwarrior's prefix match, so "the filter pins project x" is well defined.
- `FilterExpression.requiredProject` (and `TCFilter.requiredProject`) **already exists**: the one project an `.and` chain allows, nil for conflicting projects, an empty `project:`, or any `.or`. The create sheet uses it for its default project, and `TaskchampTests` has 9 `test_requiredProject_*` cases.
- The default "My tasks" filter's `fullDescription` doesn't parse, so its `filterExpression` is nil and it pins nothing without a special case.
- Tests are XCTest (`taskchamp/Tests/TaskchampTests.swift`, `@testable import taskchampShared`).

## 1. Hide badges the filter already pins — DONE (2026-10-18)

Implemented as written. `requiredProject` and `requiredPriority` share one generic helper (`requiredValue`) in `FilterExpression.swift`. The pins are `TCFilter.pins`, a `TCFilterPins` struct defined in `TCFilter.swift`. `TaskListView` reads it once per list and passes it to `TaskCellView(task:openNote:pins:)`. A row whose only details were pinned now has no second line, until item 2 makes every row one line.

Taskchamp has no context or folder menus. The filter is one expression, so the rule becomes: hide a badge whose value every task the filter can match must share.

Project, priority and tags are all hidden when pinned (user decision).

- **Shared and testable:** build on the existing `requiredProject` in `FilterExpression.swift` rather than adding a parallel property:
  - Extend `requiredProject` to `.or`: `x` only if *every* operand requires the same `x`. This also improves the create sheet's default project for filters like `(project:a +x) or (project:a +y)`.
  - `requiredPriority: TCTask.Priority?`: the same rules as `requiredProject` (one value across an `.and` chain, the same value in every `.or` branch, else nil).
  - `requiredTags: Set<String>`: `.tag(x)` → `[x]`. `.and` → the union of its operands. `.or` → the intersection. Anything else → empty.
  - Possibly a small `TCFilter.pins` struct wrapping the three.
- `TaskCellView` takes the pins as a parameter (`TaskListView` computes them once from `selectedFilter`). It skips the project badge when `task.project == pins.project`, the priority badge likewise, and any tag in `requiredTags`.
- **Tests:** next to the existing `test_requiredProject_*` cases (which still hold): `(project:a or project:a)` pins a, `(project:a +x) or (project:a +y)` pins a, `(project:a or project:b)` pins nothing. `prio:H +x` pins H. `+a or +b` requires nothing, and `(+a +b) or (+a +c)` requires a. The default filter pins nothing.
- Search doesn't change the pins. It narrows the list, but it doesn't guarantee a project.

## 2. One-line rows — DONE (2026-10-18), awaiting on-device check

Implemented as written, with row padding 7 (VimNotes') and `defaultMinListRowHeight` 1. In the simulator, rows are about 36pt apart, and "Max lines per task" = 3 wraps long descriptions in the left column with the details on the first line. Rows with badges come out about 1.3pt taller than rows without, because a badge is slightly taller than the 14pt line. Still to check on the phone: edit mode, the note button's tap area, and swipes. VimNotes has no connection set up in the simulator, so the heights haven't been compared side by side.

Follow the VimNotes row, adapted to what a task shows:

```
Description ▶ ↻ ……………  [work] [H] [tag] [tag2]  Oct 21 3:00 PM  ▤
```

- **Order:** description, then the active (`play.fill`) and recurring icons right after it, as now. Then `Spacer(minLength: 8)`, then a trailing group with `.layoutPriority(1)`:
  - **Badges:** the project and priority badges, then the **first** user tag not pinned by the filter (by name, so it's stable), then a `+n` badge (green, like tags) for the rest (user decision 2026-10-18). Cap each project and tag badge at about 80pt with `.frame(maxWidth:).fixedSize()`, as a `maxWidth` option on `TagBadge`. Priority is one letter.
  - **Due date**, with its time whenever it has one, as `dueText` does today.
  - **Note button** last, at the right edge: `.borderless`, with the enlarged tap area. Give it a fixed slot, drawn empty when there's no note, so the right edge of the date lines up on every row. In edit mode (`openNote` is nil) drop the slot on every row, since the selection circle takes about 40pt. The enlarged tap area must not change the layout: today the vertical `+8`/`-8` padding around `.contentShape` keeps the row from growing, but the `.padding(.leading, 16)` is real width. Next to a `Spacer` that was free, but in the trailing group it costs the description 16pt on every row, so cancel it the same way (`-16` after `.contentShape`).
- **Width budget** (measured 2026-10-18, default text size, 402pt-wide phone, about 370pt after insets): project `work` + `H` + two tags + "Oct 21 3:00 PM" + the note slot is about 287pt, which leaves the description about 63pt (about 10 characters), and about 25pt in edit mode. With badges at `fixedSize`, a third tag would have overflowed the row. That's why only one tag is shown, followed by `+n`.
- **Date width varies.** Because times are always shown, "Oct 21 3:00 PM" sits beside "Oct 21", so a fixed date column (VimNotes' hidden template) would waste room on most rows. Instead, right-align the date against the note slot, with no fixed width. Dates line up on their right edge, and the badges' position varies with the date's width. Older years print as `9/30/24`, as in VimNotes, to save width. A shorter time, such as dropping `:00`, is optional.
- **Keep "Max lines per task"** (`taskCellLineLimit`, 1–5, default 1; decision 9). The details never get a line of their own. A description longer than one line wraps within its own column on the left: `.lineLimit(lineLimit)` on the description, and `HStack(alignment: .firstTextBaseline)` on the outer row, so the icons, badges, date and note button stay aligned with the first line. Short tasks stay one line, and only long ones make the row taller. Text can't flow underneath the badges, since SwiftUI doesn't wrap text around views, so don't attempt that.
- **Row height:** match VimNotes' three heights. The user likes them: Medium is their default there, and they use Small and Large at times. Height is the title's line height plus fixed padding, so use VimNotes' sizes and padding and `.environment(\.defaultMinListRowHeight, 1)`. Without that, iOS 26 pads short rows up to about 52pt and Small and Medium look alike. Adjust taskchamp's padding and row insets (today 4 and 2) until screenshots at each size match VimNotes'.
- **List:** `.navigationLinkIndicatorVisibility(.hidden)` on each `NavigationLink`. Keep the swipe actions, edit-mode multi-select and the note button's tap separate from the row's tap.
- **Keep:** completed and deleted rows at `.opacity(0.45)`, the red strikethrough on deleted rows only, and the red overdue date.

## 3. Title size — DONE (2026-10-18), menus awaiting on-device check

Implemented as written: `TaskTitleSize` (in `TaskCellView.swift`) under `TCUserDefaults.taskCellTitleSize`, a Title Size picker in the Options menu, and "Title size" above "Max lines per task" in App Settings. The default is Small (14pt, the old size); the user uses Medium in VimNotes. In the simulator, rows are about 36, 38 and 40pt at Small, Medium and Large.

- **Setting:** add `TCUserDefaults.taskCellTitleSize`, read with `@AppStorage(TCUserDefaults.taskCellTitleSize.rawValue)`, as `taskCellLineLimit` is. App-only (`.standard`) is enough, since the widget draws its own rows.
- **Sizes:** a `ListTitleSize`-style enum, Small/Medium/Large = 14/16/18pt, where Small is today's size. Scale the description font with `@ScaledMetric(relativeTo: .subheadline)` as VimNotes does. Only the description changes.
- **Both places** (user decision 2026-10-18): a "Title Size" submenu in the ellipsis Options menu, next to "Sort by", and a picker in App Settings beside "Max lines per task". Both bind the same `@AppStorage` key.

## Verification

- **Build and tests:** the build, `make test` and simulator steps above still apply. The new pin tests must pass.
- **Screenshots:** the default filter, a `project:work` filter (project badges gone), a `prio:H` filter (priority badges gone), a filter with `+tag` (that tag's badges gone), a task with several tags and a long description (at max lines 1 and 3), a timed task, an overdue task, and edit mode. Then each title size.
- **Simulator data:** the simulator writes to real task data, so use throwaway tasks (see Verification above).
- **Seeding settings:** `xcrun simctl spawn … defaults write <bundle id>` lands in the simulator-wide preferences file, which the app reads but never writes, so a test can pass for the wrong reason. Write test values into the app container's `Library/Preferences/<bundle id>.plist` instead, or for the app group into the group container's plist, as the Round 1 sync setup does.
- **Menus:** they can't be opened from the command line, so the user checks the menus on the phone.

## Follow-ups found while verifying item 1 (2026-10-18, not yet fixed)

The user wants to come back to these after Round 4.

- **Long filter titles overlap the header.** With `(project:fact +correct) or (project:fact +memory)`, the header's `fact +correct | fact +memory` runs over the DEV badge and the Edit button instead of truncating. The principal `headerView` (`filterSwitcherMenu`) isn't limited to the space between the toolbar buttons.
- **A filter matching nothing showed a blank list.** With `status:pending project:work +work`, the screen had no rows and no "No tasks found" overlay. The overlay needs `tasks.isEmpty && !rebuildingCache`. The screenshot was taken about 9 s after launch, possibly before the first sync finished, so check whether it ever appears.

1. **Tags:** show all of them. The user has few tags.
2. **Due time:** show it for every task that has one, so the date column has no fixed width (see item 2).
3. ~~**One line always.** Remove "Max lines per task".~~ Reversed by decision 9.
4. **Chevron:** hide it.
5. **Pinned priority:** hide the priority badge too, as for project and tags.

## Decisions (user, 2026-10-18, after review)

6. **Extra tags:** show the first tag, then `+n` (see the width budget in item 2).
7. **Row heights:** match VimNotes' three sizes. Medium is the user's usual size.
8. **Title Size** goes in both the Options menu and App Settings.
9. **Keep "Max lines per task"** alongside Title Size. They are separate settings: size sets each line's height, max lines sets how many lines the description may wrap to (in its left column, see item 2), and row height = lines × line height + padding. The user plans the same change for VimNotes' `NoteRowView`, which has only ever shown one line.
