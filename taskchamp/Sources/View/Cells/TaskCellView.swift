import SwiftUI
import taskchampShared

/// The task list's description sizes, picked in the Options menu or App Settings. Only the description
/// changes; the padding and badges don't, so rows grow and shrink with it.
enum TaskTitleSize: Int, CaseIterable, Identifiable {
    case small
    case medium
    case large

    var id: Self {
        self
    }

    /// At the default system text size; scaled with it otherwise.
    var points: CGFloat {
        switch self {
        case .small: 14
        case .medium: 16
        case .large: 18
        }
    }

    var label: String {
        switch self {
        case .small: "Small"
        case .medium: "Medium"
        case .large: "Large"
        }
    }
}

public struct TaskCellView: View {
    let task: TCTask
    /// Opens the task's vimango note. When set, the row keeps a slot for the note button at its right
    /// edge, filled when the task has a note. Nil in edit mode, which needs the room.
    var openNote: (() -> Void)?
    /// What the selected filter pins. Every row would repeat it, so it gets no badge.
    var pins = TCFilterPins()

    @AppStorage(TCUserDefaults.taskCellLineLimit.rawValue) private var lineLimit: Int = 1
    @AppStorage(TCUserDefaults.taskCellTitleSize.rawValue) private var titleSize = TaskTitleSize.small
    /// Follows the system text size, as the badges and date already do; a bare `.system(size:)`
    /// would ignore it. 1 at the default size.
    @ScaledMetric(relativeTo: .subheadline) private var titleScale: CGFloat = 1

    private var shownProject: String? {
        guard let project = task.project, project != pins.project else { return nil }
        return project
    }

    private var shownPriority: TCTask.Priority? {
        guard let priority = task.priority, priority != .none, priority != pins.priority else { return nil }
        return priority
    }

    /// By name, so the one tag a row has room for is the same on every load.
    private var shownTags: [TCTag] {
        (task.tags?.filter { !$0.isSynthetic() && !pins.tags.contains($0.name) } ?? [])
            .sorted { $0.name < $1.name }
    }

    private var isOverdue: Bool {
        guard let due = task.due, task.status == .pending else { return false }
        return due < Date()
    }

    /// One line of details: the description and its icons, then the badges, due date and note button
    /// at the right edge. The trailing group is laid out first, so the description is what gets cut
    /// short, or wraps (up to the "Max lines per task" setting) while the details stay on its first line.
    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(task.description)
                .font(.system(size: titleSize.points * titleScale))
                .lineLimit(max(1, min(lineLimit, 5)))
                .truncationMode(.tail)
                .strikethrough(task.isDeleted, color: .red)
            if task.isActive {
                Image(systemName: SFSymbols.playFill.rawValue)
                    .font(.caption)
                    .foregroundStyle(.tint)
            }
            if task.isRecurring {
                Image(systemName: SFSymbols.recurringTask.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            details
                .layoutPriority(1)
        }
        .padding(.vertical, 7)
        .opacity(task.isCompleted || task.isDeleted ? 0.45 : 1)
    }

    private var details: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            if let project = shownProject {
                TagBadge(text: project, color: .blue, maxWidth: 80)
            }
            if let priority = shownPriority {
                TagBadge(text: priority.rawValue, color: priorityColor(priority), tintedText: true)
            }
            // Room for one tag; the rest are counted.
            if let tag = shownTags.first {
                TagBadge(text: tag.name, color: .green, maxWidth: 80)
            }
            if shownTags.count > 1 {
                TagBadge(text: "+\(shownTags.count - 1)", color: .green)
            }
            if task.due != nil {
                Text(dueText)
                    .font(.caption2)
                    .foregroundStyle(isOverdue ? .red : .secondary)
                    .lineLimit(1)
            }
            if let openNote {
                noteSlot(openNote)
            }
        }
    }

    /// The note button, or an empty slot of the same width, so dates end at the same place on every row.
    @ViewBuilder
    private func noteSlot(_ openNote: @escaping () -> Void) -> some View {
        let glyph = Image(systemName: SFSymbols.noteOpen.rawValue).font(.caption)
        if task.hasNote {
            Button(action: openNote) {
                glyph
                    .foregroundStyle(Color(asset: TaskchampAsset.Assets.accentColor))
                    // A bigger target than the glyph, without making the row taller or the slot wider.
                    .padding(.leading, 16)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .padding(.leading, -16)
                    .padding(.vertical, -8)
            }
            // Takes its own tap instead of the row's NavigationLink.
            .buttonStyle(.borderless)
            .accessibilityLabel("Open note")
        } else {
            glyph
                .hidden()
                .accessibilityHidden(true)
        }
    }

    /// Compact due date: "Today", "Tomorrow", "Oct 1", or "9/30/24" in another year, with the time
    /// when it isn't midnight.
    private var dueText: String {
        guard let due = task.due else { return "" }
        let calendar = Calendar.current
        var text: String
        if calendar.isDateInToday(due) {
            text = "Today"
        } else if calendar.isDateInTomorrow(due) {
            text = "Tomorrow"
        } else if calendar.isDateInYesterday(due) {
            text = "Yesterday"
        } else if calendar.isDate(due, equalTo: Date(), toGranularity: .year) {
            text = due.formatted(.dateTime.month(.abbreviated).day())
        } else {
            text = due.formatted(.dateTime.month(.defaultDigits).day().year(.twoDigits))
        }
        if due != calendar.startOfDay(for: due) {
            text += " " + due.formatted(date: .omitted, time: .shortened)
        }
        return text
    }

    private func priorityColor(_ priority: TCTask.Priority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        case .none: return .secondary
        }
    }
}
