import Foundation
import Network
import Observation

/// What the task list's sync button shows: whether the last sync failed, how many tasks have
/// changes the server doesn't have, and whether the server has changes this device hasn't pulled.
///
/// `TaskchampionService.sync` reports every sync here. The server side comes from `probe`, which
/// asks without syncing. Nothing syncs on its own apart from the launch sync and each write's.
@MainActor
@Observable
public final class SyncStatus {
    public static let shared = SyncStatus()

    /// Whether the last sync failed. Cleared by the next one that succeeds.
    public private(set) var lastSyncFailed = false
    /// Tasks with local changes the server doesn't have yet, as of the last sync.
    public private(set) var unsyncedTaskCount = 0
    /// Whether the last probe found changes on the server. Cleared by a successful sync.
    public private(set) var serverHasChanges = false
    private var syncsInFlight = 0

    public var isSyncing: Bool {
        syncsInFlight > 0
    }

    /// Bumped as each sync starts and ends, so a probe that a sync overlapped drops its answer.
    @ObservationIgnored private var generation = 0
    @ObservationIgnored private var hasSynced = false
    /// When a probe was last attempted, or a sync last succeeded, for the debounce in `probe`.
    /// A failed probe counts too, or an app flipped in and out while offline would retry each time.
    @ObservationIgnored private var lastProbeAttempt: Date?
    @ObservationIgnored private let pathMonitor = NWPathMonitor()
    @ObservationIgnored private var wasOnline = true

    private static let probeDebounce: TimeInterval = 60
    /// Nothing waits on a probe, so giving up early costs only a missing arrow.
    private static let probeTimeout: TimeInterval = 8
    /// Serial, so a probe stalled past its deadline never has more than one running beside it.
    private nonisolated static let probeQueue = DispatchQueue(label: "com.slzatz.taskchamp.probe", qos: .utility)

    private init() {}

    func syncStarted() {
        syncsInFlight += 1
        generation += 1
    }

    /// `succeeded` is nil for a sync that was cancelled, and `unsyncedTasks` is -1 when unknown.
    func syncEnded(succeeded: Bool?, unsyncedTasks: Int) {
        syncsInFlight -= 1
        generation += 1
        guard let succeeded else {
            return
        }
        hasSynced = true
        lastSyncFailed = !succeeded
        if unsyncedTasks >= 0 {
            unsyncedTaskCount = unsyncedTasks
        }
        if succeeded {
            // A sync just answered the probe's question.
            serverHasChanges = false
            lastProbeAttempt = Date()
        }
    }

    /// Asks the server, without syncing, whether another machine has synced since this device
    /// last did, and shows the answer as `serverHasChanges`. The app runs it on each return to the
    /// foreground, every 15 minutes while in front, and on reconnecting.
    ///
    /// The same rules as VimNotes' probe keep it safe to run unattended:
    /// - **Silent.** A failure only clears the arrow; it never sets `lastSyncFailed`.
    /// - **Bounded.** It gives up after `probeTimeout`.
    /// - **Debounced** to a minute unless `force`d, since foregrounding can come in bursts.
    ///
    /// It waits for this process's first sync, which answers the question better, and drops an
    /// answer that a sync overlapped.
    public func probe(force: Bool = false) async {
        guard hasSynced, !isSyncing else {
            return
        }
        if !force, let lastProbeAttempt, Date().timeIntervalSince(lastProbeAttempt) < Self.probeDebounce {
            return
        }
        lastProbeAttempt = Date()
        guard let check = TaskchampionService.shared.serverProbe() else {
            return
        }
        let generation = generation
        let answer = await Self.firstOf(Self.probeTimeout, check)
        guard generation == self.generation else {
            return
        }
        serverHasChanges = answer ?? false
    }

    /// Probes when the network comes back: the server may well have changed while offline.
    public func startNetworkMonitor() {
        guard pathMonitor.pathUpdateHandler == nil else {
            return
        }
        pathMonitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            // Delivered on `.main`, per `start(queue:)` below.
            MainActor.assumeIsolated {
                self?.networkChanged(online: online)
            }
        }
        pathMonitor.start(queue: .main)
    }

    private func networkChanged(online: Bool) {
        defer { wasOnline = online }
        if online, !wasOnline {
            Task { await probe(force: true) }
        }
    }

    /// `work`'s result, or nil if `timeout` passes first. Returns at the deadline even though
    /// `work` keeps running: the bridge's network call can't be cancelled.
    private nonisolated static func firstOf(
        _ timeout: TimeInterval,
        _ work: @escaping @Sendable () -> Bool?
    ) async -> Bool? {
        await withCheckedContinuation { continuation in
            let race = FirstResult(continuation)
            probeQueue.async {
                race.resolve(work())
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                race.resolve(nil)
            }
        }
    }
}

/// Resumes a continuation with the first value it's given and ignores the rest.
private final class FirstResult<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<T, Never>?

    init(_ continuation: CheckedContinuation<T, Never>) {
        self.continuation = continuation
    }

    func resolve(_ value: T) {
        lock.lock()
        let continuation = continuation
        self.continuation = nil
        lock.unlock()
        continuation?.resume(returning: value)
    }
}
