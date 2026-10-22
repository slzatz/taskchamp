import Foundation
import Taskchampion
import WidgetKit

// swiftlint:disable:next type_body_length
public class TaskchampionService {
    public static let shared = TaskchampionService()
    private var replica: Replica?
    private var path: String?
    public var needToSync = false
    private var currentTask: _Concurrency.Task<Void, Error>?
    private let syncReplicaStore = SyncReplicaStore()

    /// WidgetKit reloads the widget itself after each timeline and widget intent. A sync there that
    /// also reloaded all timelines asked for another timeline, which synced again, round and round.
    private static let isWidgetExtension =
        (Bundle.main.object(forInfoDictionaryKey: "NSExtension") as? [String: Any])?["NSExtensionPointIdentifier"]
            as? String == "com.apple.widgetkit-extension"

    public enum SyncType: Codable, CaseIterable {
        case remote
        case aws
        case gcp
        case local
        case none
    }

    public func getSyncServiceFromType(_ type: TaskchampionService.SyncType) -> SyncServiceProtocol.Type {
        switch type {
        case .none:
            return NoSyncService.self
        case .local:
            return ICloudSyncService.self
        case .remote:
            return RemoteSyncService.self
        case .gcp:
            return GcpSyncService.self
        case .aws:
            return AwsSyncService.self
        }
    }

    public func setDbUrl(path: String) throws {
        if replica != nil, self.path != nil, self.path == path {
            return
        }
        replica = Taskchampion.new_replica_on_disk(path, true, true)
        if replica == nil {
            throw TCError.genericError("Failed to create replica")
        }
        self.path = path
    }

    public func deleteReplica() throws {
        guard let path else {
            throw TCError.genericError("Database not set")
        }
        do {
            let newPath = path + "/taskchampion.sqlite3"
            syncReplicaStore.reset()
            try FileManager.default.removeItem(atPath: newPath)
            replica = nil
            self.path = nil
        } catch {
            throw TCError.genericError("Failed to delete replica: \(error.localizedDescription)")
        }
    }

    public func sync(syncType: SyncType, onSync: @escaping () -> Void = {}) async throws {
        currentTask?.cancel()
        currentTask = .init {
            guard let path else {
                throw TCError.genericError("Database not set")
            }

            let syncService = getSyncServiceFromType(syncType)

            await SyncStatus.shared.syncStarted()
            do {
                // Sync on the dedicated sync replica, never the main-actor one (see SyncReplicaStore).
                let (synced, unsyncedTasks) = try await syncReplicaStore.run(path: path) { replica in
                    let synced = try syncService.sync(replica: replica)
                    // Counted on the sync queue, so it never waits on a sync of ours holding the lock.
                    return (synced, Int(Taskchampion.count_unsynced_tasks(path)))
                }

                if synced {
                    needToSync = false
                } else {
                    needToSync = true
                }
                await SyncStatus.shared.syncEnded(succeeded: synced, unsyncedTasks: unsyncedTasks)
                if !Self.isWidgetExtension {
                    WidgetCenter.shared.reloadAllTimelines()
                }
                onSync()
            } catch is CancellationError {
                // do nothing: task was canceled before finishing
                await SyncStatus.shared.syncEnded(succeeded: nil, unsyncedTasks: -1)
            } catch {
                needToSync = true
                await SyncStatus.shared.syncEnded(succeeded: false, unsyncedTasks: -1)
                onSync()
            }
        }
        try await currentTask?.value
    }

    /// A check, to run off the main thread, of whether the selected sync backend has changes this
    /// device hasn't pulled. Nil when no database is open. See `SyncStatus.probe`.
    func serverProbe() -> (@Sendable () -> Bool?)? {
        guard let path else {
            return nil
        }
        let syncService = getSyncServiceFromType(FileService.shared.getSelectedSyncType() ?? .none)
        return { syncService.probe(path: path) }
    }

    public func sync(onSync: @escaping () -> Void = {}) async throws {
        let syncType: SyncType = FileService.shared.getSelectedSyncType() ?? .none
        try await sync(syncType: syncType, onSync: onSync)
    }

    @MainActor
    public func getTasks(
        sortType: TasksHelper.TCSortType = .defaultSort,
        filter: TCFilter = TCFilter.defaultFilter
    ) throws -> [TCTask] {
        guard let replica else {
            throw TCError.genericError("Database not set")
        }
        var taskObjects: [TCTask] = []
        if filter.isDefaultFilter {
            taskObjects = try getPendingTasks()
            TCTask.markLatestTask(in: &taskObjects)
            TasksHelper.sortTasksWithSortType(&taskObjects, sortType: sortType)
            return taskObjects
        }

        let tasks = replica.all_tasks()
        guard let tasks else {
            throw TCError.genericError("Query was null")
        }
        taskObjects = tasks.compactMap {
            let task = TCTask.taskFactory(from: $0, withFilter: filter)
            if let task {
                return task
            }
            return nil
        }

        TCTask.markLatestTask(in: &taskObjects)
        TasksHelper.sortTasksWithSortType(&taskObjects, sortType: sortType)
        return taskObjects
    }

    @MainActor
    public func getAllProjects(onlyActive: Bool = false) -> [String] {
        guard let replica else { return [] }
        let rawTasks = onlyActive ? replica.pending_tasks() : replica.all_tasks()
        guard let rawTasks else { return [] }
        var seen = Set<String>()
        var projects: [String] = []
        for raw in rawTasks {
            let project = TCTask(from: raw).project ?? ""
            let trimmed = project.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !seen.contains(trimmed) else { continue }
            seen.insert(trimmed)
            projects.append(trimmed)
        }
        return projects.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    @MainActor
    public func getPendingTasks() throws -> [TCTask] {
        guard let replica else {
            throw TCError.genericError("Database not set")
        }

        let tasks = replica.pending_tasks()
        guard let tasks else {
            throw TCError.genericError("Query was null")
        }
        return tasks.map { TCTask(from: $0) }
    }

    @MainActor
    public func getTask(uuid: String) throws -> TCTask {
        guard let replica else {
            throw TCError.genericError("Database not set")
        }
        let task = replica.get_task(uuid)
        guard let task else {
            throw TCError.genericError("Task not found")
        }
        return TCTask(from: task)
    }

    @MainActor
    public func togglePendingTasksStatus(
        uuids: Set<String>,
        skipSync: Bool = false,
        onSync: @escaping () -> Void = {}
    ) throws {
        for uuid in uuids {
            let task = try getTask(uuid: uuid)
            var newStatus: TCTask.Status = .pending
            if task.status == .pending {
                newStatus = .completed
            } else if task.status == .completed {
                newStatus = .pending
            }
            var updatedTask = task
            updatedTask.status = newStatus
            try updateTask(updatedTask, skipSync: true)
        }
        if skipSync {
            return
        }
        _Concurrency.Task.detached {
            try? await self.sync {
                onSync()
            }
        }
    }

    @MainActor
    public func updatePendingTasks(
        _ uuids: Set<String>,
        withStatus newStatus: TCTask.Status,
        onSync: @escaping () -> Void = {}
    ) throws {
        for uuid in uuids {
            let task = try getTask(uuid: uuid)
            var updatedTask = task
            updatedTask.status = newStatus
            try updateTask(updatedTask, skipSync: true)
        }
        _Concurrency.Task.detached {
            try? await self.sync {
                onSync()
            }
        }
    }

    public func updateTask(_ task: TCTask, skipSync: Bool = false, onSync: @escaping () -> Void = {}) throws {
        guard let replica else {
            throw TCError.genericError("Database not set")
        }
        let priority = (task.priority == TCTask.Priority.none || task.priority == nil) ? ""
            .intoRustString() : task
            .priority?.rawValue
            .intoRustString()
        let due = task.due?.timeIntervalSince1970.rounded()
        let dueString = due != nil ? String(Int(due ?? 0)) : nil

        let task = replica.update_task(
            task.uuid.intoRustString(),
            task.description.intoRustString(),
            dueString?.intoRustString(),
            priority,
            task.project?.intoRustString(),
            task.status.rawValue.intoRustString(),
            nil, // annotations are added once, by linkVimangoNote, not on every save
            task.rustVecOfTags
        )
        if task == nil {
            throw TCError.genericError("Failed to update task")
        }

        _ = replica.sync_no_server() // rebuild the working set

        if skipSync {
            return
        }

        _Concurrency.Task.detached {
            try? await self.sync {
                onSync()
            }
        }
    }

    public func startTask(_ uuid: String, onSync: @escaping () -> Void = {}) throws {
        guard let replica else {
            throw TCError.genericError("Database not set")
        }
        let task = replica.start_task(uuid.intoRustString())
        if task == nil {
            throw TCError.genericError("Failed to start task")
        }
        _ = replica.sync_no_server()
        _Concurrency.Task.detached {
            try? await self.sync {
                onSync()
            }
        }
    }

    public func stopTask(_ uuid: String, onSync: @escaping () -> Void = {}) throws {
        guard let replica else {
            throw TCError.genericError("Database not set")
        }
        let task = replica.stop_task(uuid.intoRustString())
        if task == nil {
            throw TCError.genericError("Failed to stop task")
        }
        _ = replica.sync_no_server()
        _Concurrency.Task.detached {
            try? await self.sync {
                onSync()
            }
        }
    }

    /// Records that the task has a vimango note, as a `vimango` annotation.
    /// Does nothing if the task already has that exact annotation.
    public func linkVimangoNote(uuid: String, onSync: @escaping () -> Void = {}) throws {
        guard let replica else {
            throw TCError.genericError("Database not set")
        }
        let task = replica.annotate_task(
            uuid.intoRustString(),
            TCTask.vimangoNoteAnnotation.intoRustString()
        )
        if task == nil {
            throw TCError.genericError("Failed to annotate task")
        }
        _ = replica.sync_no_server()
        _Concurrency.Task.detached {
            try? await self.sync {
                onSync()
            }
        }
    }

    public func createTask(_ task: TCTask, skipSync: Bool = false, onSync: @escaping () -> Void = {}) throws {
        guard let replica else {
            throw TCError.genericError("Database not set")
        }
        let priority = (task.priority == TCTask.Priority.none || task.priority == nil) ? "".intoRustString() : task
            .priority?.rawValue
            .intoRustString()
        let due = task.due?.timeIntervalSince1970.rounded()
        let dueString = due != nil ? String(Int(due ?? 0)) : nil

        let created = replica.create_task(
            task.uuid.intoRustString(),
            task.description.intoRustString(),
            dueString?.intoRustString(),
            priority,
            task.project?.intoRustString(),
            task.rustVecOfTags
        )
        if created == nil {
            throw TCError.genericError("Failed to create task")
        }
        // A task created from a vimango note. The task exists either way, so a
        // failed annotation only costs the note button its label.
        if task.hasNote {
            _ = replica.annotate_task(task.uuid.intoRustString(), TCTask.vimangoNoteAnnotation.intoRustString())
        }

        _ = replica.sync_no_server() // rebuild the working set

        if skipSync {
            return
        }
        _Concurrency.Task.detached {
            try? await self.sync {
                onSync()
            }
        }
    }
}
