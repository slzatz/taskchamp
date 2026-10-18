import AppIntents
import taskchampShared
import WidgetKit

struct CreateTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Create Task"
    static var description = IntentDescription("Create a task via natural language.")

    @Parameter(title: "Command line input") var taskInput: String

    init(taskInput: String) {
        self.taskInput = taskInput
    }

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        let destinationPath = try FileService.shared.getDestinationPathForLocalReplica()
        try TaskchampionService.shared.setDbUrl(path: destinationPath)

        let task = NLPService.shared.createTask(from: taskInput)
        try TaskchampionService.shared.createTask(task, skipSync: true)
        // Waits for the sync, or iOS could suspend the widget while the sync holds the database lock
        // and kill it (0xDEAD10CC).
        try? await TaskchampionService.shared.sync()

        return .result()
    }
}
