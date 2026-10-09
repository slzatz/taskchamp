import SwiftUI
import taskchampShared

public struct TaskCellView: View {
    let task: TCTask
    /// Opens the task's vimango note. When set and the task has a note, the row shows a note button.
    var openNote: (() -> Void)?

    @AppStorage(TCUserDefaults.taskCellLineLimit.rawValue) private var lineLimit: Int = 1

    private var userTags: [TCTag] {
        task.tags?.filter { !$0.isSynthetic() } ?? []
    }

    private var isOverdue: Bool {
        guard let due = task.due, task.status == .pending else { return false }
        return due < Date()
    }

    private var hasDetails: Bool {
        task.project != nil || task.priority != nil || !userTags.isEmpty || task.due != nil
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(task.description)
                    .font(.system(size: 14))
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
                Spacer()
                if task.hasNote, let openNote {
                    Button(action: openNote) {
                        Image(systemName: SFSymbols.noteOpen.rawValue)
                            .font(.caption)
                            .foregroundStyle(Color(asset: TaskchampAsset.Assets.accentColor))
                            // A bigger target than the glyph, without making the row taller.
                            .padding(.leading, 16)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                            .padding(.vertical, -8)
                    }
                    // Takes its own tap instead of the row's NavigationLink.
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Open note")
                }
            }
            if hasDetails {
                HStack(spacing: 6) {
                    if let project = task.project {
                        TagBadge(text: project, color: .blue)
                    }
                    if let priority = task.priority, priority != .none {
                        TagBadge(text: priority.rawValue, color: priorityColor(priority), tintedText: true)
                    }
                    ForEach(userTags, id: \.name) { tag in
                        TagBadge(text: tag.name, color: .green)
                    }
                    Spacer()
                    if task.due != nil {
                        Text(dueText)
                            .font(.caption2)
                            .foregroundStyle(isOverdue ? .red : .secondary)
                    }
                }
                .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
        .opacity(task.isCompleted || task.isDeleted ? 0.45 : 1)
    }

    /// Compact due date: "Today", "Tomorrow", or "Oct 1"; the year only when it isn't this year,
    /// and the time only when it isn't midnight.
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
            text = due.formatted(.dateTime.month(.abbreviated).day().year())
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
