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
}
