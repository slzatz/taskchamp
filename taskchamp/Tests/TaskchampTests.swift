import Foundation
@testable import taskchampShared
import XCTest

final class TaskchampTests: XCTestCase {
    private func compact(_ filter: String) -> String? {
        FilterParser.parse(filter)?.compactDescription
    }

    func test_compactDescription_statusPrioProject() {
        XCTAssertEqual(compact("status:pending prio:H project:work"), "pending H work")
    }

    func test_compactDescription_tags() {
        XCTAssertEqual(compact("+home -someday"), "+home -someday")
    }

    func test_compactDescription_orGroupInsideAnd() {
        XCTAssertEqual(compact("status:pending (project:work or project:home)"), "pending (work | home)")
    }

    func test_compactDescription_topLevelOr() {
        XCTAssertEqual(compact("prio:H or +urgent"), "H | +urgent")
    }

    func test_compactDescription_recurAndNoPriority() {
        XCTAssertEqual(compact("recur prio:None"), "recur no prio")
    }

    func test_parser_acceptsPriorityAlias() {
        XCTAssertEqual(compact("priority:M project:work"), "M work")
    }

    func test_compactTitle_usesName() {
        let filter = TCFilter(name: "Work today", fullDescription: "status:pending project:work")
        XCTAssertEqual(filter.compactTitle, "Work today")
    }

    func test_compactTitle_defaultFilter() {
        XCTAssertEqual(TCFilter.defaultFilter.compactTitle, "My tasks")
    }

    func test_compactTitle_summarizesExpression() {
        let filter = TCFilter(fullDescription: "status:pending prio:H project:work")
        XCTAssertEqual(filter.compactTitle, "pending H work")
    }

    func test_compactTitle_unparseableFallsBackToDescription() {
        let filter = TCFilter(fullDescription: "whatever words")
        XCTAssertEqual(filter.compactTitle, "whatever words")
    }

    // MARK: - Date filters

    private let now: Date = {
        var components = DateComponents()
        components.year = 2026
        components.month = 10
        components.day = 3
        components.hour = 15
        return Calendar.current.date(from: components) ?? Date()
    }()

    private func completedTask(endedDaysAgo days: Int?) -> TCTask {
        var task = TCTask(uuid: UUID().uuidString, project: "work", description: "t", status: .completed)
        task.end = days.flatMap { Calendar.current.date(byAdding: .day, value: -$0, to: now) }
        return task
    }

    private func matches(_ filter: String, _ task: TCTask) -> Bool {
        FilterParser.parse(filter)?.matches(task, now: now) ?? false
    }

    func test_endAfter_matchesRecentlyCompleted() {
        let filter = "project:work status:completed end.after:now-1wk"
        XCTAssertTrue(matches(filter, completedTask(endedDaysAgo: 2)))
        XCTAssertFalse(matches(filter, completedTask(endedDaysAgo: 10)))
        XCTAssertFalse(matches(filter, completedTask(endedDaysAgo: nil)))
    }

    func test_endBefore_andAliases() {
        XCTAssertTrue(matches("end.before:today-3d", completedTask(endedDaysAgo: 5)))
        XCTAssertFalse(matches("end.before:today-3d", completedTask(endedDaysAgo: 1)))
        XCTAssertTrue(matches("end.below:yesterday", completedTask(endedDaysAgo: 2)))
        XCTAssertTrue(matches("end.above:-2d", completedTask(endedDaysAgo: 1)))
    }

    func test_endAfter_isoDate() {
        XCTAssertTrue(matches("end.after:2026-09-30", completedTask(endedDaysAgo: 2)))
        XCTAssertFalse(matches("end.after:2026-09-30", completedTask(endedDaysAgo: 5)))
    }

    func test_filterDate_resolvesRelativeValues() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        XCTAssertEqual(FilterDate("today")?.resolve(now: now), today)
        XCTAssertEqual(FilterDate("now-1wk")?.resolve(now: now), calendar.date(byAdding: .day, value: -7, to: now))
        XCTAssertEqual(FilterDate("now-2mo")?.resolve(now: now), calendar.date(byAdding: .month, value: -2, to: now))
        XCTAssertEqual(FilterDate("now-30min")?.resolve(now: now), now.addingTimeInterval(-1800))
        XCTAssertNil(FilterDate("now-1fortnight"))
        XCTAssertNil(FilterDate("someday"))
    }

    func test_compactDescription_dateFilter() {
        XCTAssertEqual(compact("status:completed end.after:now-1wk"), "completed end>now-1wk")
    }

    func test_unrecognizedTerms() {
        XCTAssertEqual(FilterParser.unrecognizedTerms(in: "task project:work end.after:now-1wk"), [])
        XCTAssertEqual(FilterParser.unrecognizedTerms(in: "project:work due:today end.after:bogus"), [
            "due:today", "end.after:bogus"
        ])
    }

    func test_vimangoNoteTitle_onlyFromVimangoAnnotations() {
        XCTAssertEqual(TCTask.vimangoNoteTitle(fromAnnotation: "vimango: Fix the gate"), "Fix the gate")
        XCTAssertNil(TCTask.vimangoNoteTitle(fromAnnotation: "task-note: Fix-the-gate"))
        XCTAssertNil(TCTask.vimangoNoteTitle(fromAnnotation: "called the vimango: guy"))
    }

    func test_vimangoNote_decodesAndEncodesAsOneAnnotation() throws {
        let json = """
        {"uuid": "u", "description": "Fix the gate", "status": "pending",
         "annotation_1700000000": "vimango: Gate", "annotation_1700000001": "called the plumber"}
        """
        let task = try JSONDecoder().decode(TCTask.self, from: Data(json.utf8))
        XCTAssertEqual(task.vimangoNote, "Gate")
        XCTAssertEqual(task.noteAnnotationKey, "annotation_1700000000")

        let encoded = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(task)) as? [String: Any]
        )
        let annotations = encoded.filter { $0.key.hasPrefix("annotation_") }
        XCTAssertEqual(annotations.count, 1)
        XCTAssertEqual(annotations["annotation_1700000000"] as? String, "vimango: Gate")
    }

    /// What `PathStore` would need to restore a task screen: every field the
    /// screen reads comes back from JSON.
    func test_codable_roundTripKeepsEveryField() throws {
        func date(_ seconds: TimeInterval) -> Date {
            Date(timeIntervalSince1970: seconds)
        }
        var task = TCTask(
            uuid: "6f1c2a5e-0b7d-4c3e-9a8f-1d2e3f4a5b6c",
            project: "home",
            description: "Fix the gate",
            status: .pending,
            priority: .high,
            due: date(1_800_000_000),
            vimangoNote: "Gate",
            tags: [TCTag(name: "outside")],
            recur: "weekly"
        )
        task.scheduled = date(1_790_000_000)
        task.until = date(1_810_000_000)
        task.modified = date(1_785_000_000)
        task.end = date(1_786_000_000)
        task.entry = date(1_780_000_000)

        let decoded = try JSONDecoder().decode(TCTask.self, from: JSONEncoder().encode(task))

        XCTAssertEqual(decoded.uuid, task.uuid)
        XCTAssertEqual(decoded.project, "home")
        XCTAssertEqual(decoded.description, "Fix the gate")
        XCTAssertEqual(decoded.status, .pending)
        XCTAssertEqual(decoded.priority, .high)
        XCTAssertEqual(decoded.recur, "weekly")
        XCTAssertEqual(decoded.tags?.map(\.name), ["outside"])
        XCTAssertEqual(decoded.vimangoNote, "Gate")
        XCTAssertEqual(decoded.due, task.due)
        XCTAssertEqual(decoded.scheduled, task.scheduled)
        XCTAssertEqual(decoded.until, task.until)
        XCTAssertEqual(decoded.modified, task.modified)
        XCTAssertEqual(decoded.end, task.end)
        XCTAssertEqual(decoded.entry, task.entry)
    }

    func test_codable_absentDatesStayNil() throws {
        let task = TCTask(uuid: "u", description: "No dates", status: .pending)
        let decoded = try JSONDecoder().decode(TCTask.self, from: JSONEncoder().encode(task))
        XCTAssertNil(decoded.due)
        XCTAssertNil(decoded.scheduled)
        XCTAssertNil(decoded.until)
        XCTAssertNil(decoded.modified)
        XCTAssertNil(decoded.end)
        XCTAssertNil(decoded.entry)
    }
}
