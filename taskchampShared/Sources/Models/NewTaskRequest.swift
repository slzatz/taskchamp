import Foundation

/// What a `task/new` deep link asks the create sheet to start with.
///
/// `content` is command-line input, parsed like typed text (widgets, Shortcuts).
/// The other fields come from VimNotes' "Create task" button on a note:
/// `taskchampdev://task/new?uuid=<uuid>&title=<note title>&project=<context>`.
/// VimNotes picks the uuid and stores it as the note's link (its synced
/// `taskwarrior_uuid` column), so creating the task with that uuid is what
/// links the two.
public struct NewTaskRequest: Hashable, Identifiable {
    public var content = ""
    /// The description, taken literally rather than parsed, since a note title
    /// may contain words like `due:` or `+tag`.
    public var description = ""
    public var project: String?
    /// The uuid of the vimango note's task, lowercased like taskchampion's own.
    public var noteTaskUUID: String?

    /// The request itself, for `.sheet(item:)`.
    public var id: Self {
        self
    }

    public init(content: String = "") {
        self.content = content
    }

    public init(url: URL) {
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        func value(_ name: String) -> String? {
            let value = items.first { $0.name == name }?.value?.trimmingCharacters(in: .whitespacesAndNewlines)
            return value?.isEmpty == false ? value : nil
        }
        content = value("content") ?? ""
        description = value("title") ?? ""
        project = value("project")
        noteTaskUUID = value("uuid").flatMap(UUID.init(uuidString:))?.uuidString.lowercased()
    }

    public var isEmpty: Bool {
        content.isEmpty && description.isEmpty && project == nil && noteTaskUUID == nil
    }

    /// The requested project, spelled like an existing one that matches it
    /// ignoring case, since VimNotes sends a context title.
    public func project(among projects: [String]) -> String? {
        guard let project else { return nil }
        return projects.first { $0.caseInsensitiveCompare(project) == .orderedSame } ?? project
    }
}
