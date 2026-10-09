import Foundation

public extension TCTask {
    /// Asks VimNotes for this task's note, which it finds by the uuid or creates.
    var vimangoNoteURL: URL? {
        var components = URLComponents()
        components.scheme = "vimango"
        components.host = "task-note"
        components.queryItems = [
            URLQueryItem(name: "uuid", value: uuid),
            URLQueryItem(name: "title", value: description)
        ]
        if let project, !project.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "project", value: project))
        }
        return components.url
    }
}
