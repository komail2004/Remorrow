import XCTest
@testable import Remorrow

final class SearchRankingTests: XCTestCase {
    func testSearchesAcrossTitleAndOriginalSource() {
        XCTAssertGreaterThan(SearchRanking.score("headphones return", fields: [
            "Wireless headphones", "Must return by December 1"
        ]), 0)
    }
    func testEverySearchWordMustMatchSomeField() {
        XCTAssertEqual(SearchRanking.score("headphones passport", fields: [
            "Headphones", "Electronics store"
        ]), 0)
    }
    func testEmptyQueryShowsSavedItems() {
        XCTAssertEqual(SearchRanking.score("  ", fields: ["Any"]), 1)
    }
    func testTitleMatchRanksHigherThanSourceOnly() {
        XCTAssertGreaterThan(
            SearchRanking.score("milk", fields: ["Buy milk", ""]),
            SearchRanking.score("milk", fields: ["Other task", "Buy milk"])
        )
    }

    func testNaturalQuestionIgnoresFillerWords() {
        XCTAssertGreaterThan(SearchRanking.score("Where is my headphones receipt?",
            fields: ["Wireless headphones", "receipt purchase order"]), 0)
    }

    func testThisMonthFilter() {
        let now = Date(timeIntervalSince1970: 1811000000)
        let date = now.addingTimeInterval(86400)
        XCTAssertTrue(SearchRanking.matchesDate("Which subscriptions renew this month",
                                                  date: date, now: now))
        let previous = Calendar.current.date(byAdding: .month, value: -2, to: now)!
        XCTAssertFalse(SearchRanking.matchesDate("This month", date: previous, now: now))
    }
}
