import Foundation
import Taskchampion

/// Owns a second `Replica`, opened on the same database, that is used only for syncing.
///
/// The Rust `Replica` is not thread-safe, so it must never be used from two threads at once.
/// The main `Replica` in `TaskchampionService` is only used on the main actor, and this one is
/// only used on `queue`, a serial queue, which also keeps syncs from overlapping. The two
/// SQLite connections coordinate through WAL mode, the same way the app, the widget, and
/// Taskwarrior on the desktop share one database.
final class SyncReplicaStore: @unchecked Sendable {
    // All mutable state below is only touched on `queue`.
    private let queue = DispatchQueue(label: "com.slzatz.taskchamp.sync", qos: .userInitiated)
    private var replica: Replica?
    private var path: String?

    /// Runs `body` on the sync queue with the sync replica for `path`, opening it if needed.
    func run(path: String, _ body: @escaping @Sendable (Replica) throws -> Bool) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    let replica = self.replica(for: path)
                    continuation.resume(returning: try body(replica))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Closes the sync replica, e.g. before its database file is deleted. Waits for any
    /// running sync to finish.
    func reset() {
        queue.sync {
            replica = nil
            path = nil
        }
    }

    private func replica(for path: String) -> Replica {
        if let replica, self.path == path {
            return replica
        }
        let replica = Taskchampion.new_replica_on_disk(path, true, true)
        self.replica = replica
        self.path = path
        return replica
    }
}
