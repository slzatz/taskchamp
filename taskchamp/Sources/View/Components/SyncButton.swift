import SwiftUI
import taskchampShared

/// A cloud saying what a sync would do: bring server changes down, send local ones up, or both,
/// or that the last sync failed; a spinner while syncing. Tapping syncs. Styled after VimNotes'
/// sync button.
///
/// Only the up side has a number, the tasks with unsynced changes. The server side can't count
/// tasks without downloading them, so its arrow has none. A failed sync keeps the number beside its
/// exclamation: every edit syncs, so an edit made offline fails, and the count says what's waiting.
///
/// The width never changes, or the menu beside it would shift each time the count came and went.
/// A plain cloud, the spinner and the widest count are laid out hidden (every cloud symbol has the
/// same width), so the slots size themselves to the font. The count goes beside the cloud, not on
/// its corner: the toolbar clips each item to its own bounds.
struct SyncButton: View {
    /// Also true while a view is about to sync, e.g. pull-to-refresh's pause before it starts.
    let isSyncing: Bool
    let action: () -> Void

    private var status: SyncStatus {
        .shared
    }

    var body: some View {
        let local = status.unsyncedTaskCount
        let isDue = status.lastSyncFailed || status.serverHasChanges || local > 0
        Button(action: action) {
            HStack(spacing: 3) {
                ZStack {
                    ProgressView().hidden()
                    if isSyncing {
                        ProgressView()
                    } else {
                        // Every cloud symbol draws the same cloud from the same top edge, but the
                        // up/down ones hang their arrow below it and are taller, so centering them
                        // lifted the cloud. Pinned to a plain cloud's top, only the arrow moves.
                        Image(systemName: "icloud").hidden()
                            .overlay(alignment: .top) {
                                Image(systemName: symbol)
                            }
                    }
                }
                ZStack(alignment: .leading) {
                    Text(verbatim: "99+").hidden()
                    if !isSyncing, local > 0 {
                        Text(verbatim: local > 99 ? "99+" : String(local))
                    }
                }
                .font(.subheadline.bold())
                .monospacedDigit()
            }
            // Orange: a sync is due. Nil keeps the toolbar's own color otherwise.
            .foregroundColor(isDue && !isSyncing ? .orange : nil)
        }
        .disabled(status.isSyncing)
        .accessibilityLabel(isSyncing ? "Syncing" : accessibilityText)
    }

    private var symbol: String {
        if status.lastSyncFailed {
            return "exclamationmark.icloud"
        }
        switch (status.serverHasChanges, status.unsyncedTaskCount > 0) {
        case (true, true): return "arrow.triangle.2.circlepath.icloud"
        case (true, false): return "icloud.and.arrow.down"
        case (false, true): return "icloud.and.arrow.up"
        case (false, false): return "checkmark.icloud"
        }
    }

    private var accessibilityText: String {
        var parts: [String] = []
        if status.lastSyncFailed {
            parts.append("last sync failed")
        } else if status.serverHasChanges {
            parts.append("server changes")
        }
        let local = status.unsyncedTaskCount
        if local > 0 {
            parts.append("\(local) unsynced task\(local == 1 ? "" : "s")")
        }
        return parts.isEmpty ? "Sync" : "Sync, " + parts.joined(separator: ", ")
    }
}
