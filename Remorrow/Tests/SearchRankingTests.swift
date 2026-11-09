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
}
