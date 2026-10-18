import AppIntents
import taskchampShared
import WidgetKit

struct CompleteTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Task"
    static var description = IntentDescription("The task is marked as completed.")

    @Parameter(title: "taskId") var taskId: String

    init(taskId: String) {
        self.taskId = taskId
    }

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        let destinationPath = try FileService.shared.getDestinationPathForLocalReplica()
        try TaskchampionService.shared.setDbUrl(path: destinationPath)

        try? TaskchampionService.shared.togglePendingTasksStatus(uuids: [taskId], skipSync: true)
        NotificationService.shared.removeNotifications(for: [taskId])

        // Waits for the sync, or iOS could suspend the widget while the sync holds the database lock
        // and kill it (0xDEAD10CC). The pause, which runs alongside, keeps the checked box on screen
        // for a moment before the widget reloads.
        async let pause: Void? = try? await Task.sleep(nanoseconds: 1_000_000_000)
        try? await TaskchampionService.shared.sync()
        _ = await pause
        return .result()
    }
}
