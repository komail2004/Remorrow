import XCTest
@testable import Remorrow

final class DailyBriefingTests: XCTestCase {
    func testOverdueAndSoonAreSeparate() {
        let now = Date(timeIntervalSince1970: 1800000000)
        let elements = [
            BriefingEntry(id: "old", title: "Old", dueAt: now.addingTimeInterval(-60), kind: "reminder"),
            BriefingEntry(id: "today", title: "Today", dueAt: now.addingTimeInterval(60), kind: "reminder"),
            BriefingEntry(id: "week", title: "Week", dueAt: now.addingTimeInterval(3*86400), kind: "return")
        ]
        let r = DailyBriefing.build(items: elements, now: now)
        XCTAssertEqual(r.overdue.count, 1)
        XCTAssertEqual(r.today.count + r.soon.count, 2)
        XCTAssertEqual(r.urgentCount, r.overdue.count + r.today.count)
    }

    func testEmptyBriefingIsCalm() {
        let result = DailyBriefing.build(items: [])
        XCTAssertEqual(result.headline, "Nothing urgent today.")
    }
}
