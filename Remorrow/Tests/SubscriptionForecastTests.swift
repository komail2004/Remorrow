import XCTest
@testable import Remorrow

final class SubscriptionForecastTests: XCTestCase {
    func testSixCalendarMonthsFromVerifiedDate() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let anchor = calendar.date(from: DateComponents(year: 2026, month: 1, day: 31))!
        let dates = SubscriptionForecast.dates(from: anchor, frequency: "Monthly",
                                                calendar: calendar)
        XCTAssertEqual(dates.count, 6)
        XCTAssertEqual(calendar.component(.month, from: dates[2]), 3)
        XCTAssertEqual(calendar.component(.day, from: dates[2]), 31)
    }
    func testMonthlyEquivalentUsesFrequency() {
        XCTAssertEqual(SubscriptionForecast.monthlyEquivalent(amount: 120, frequency: "Yearly"), 10)
        XCTAssertEqual(SubscriptionForecast.monthlyEquivalent(amount: 12, frequency: "Monthly"), 12)
        XCTAssertNil(SubscriptionForecast.monthlyEquivalent(amount: 12, frequency: "Other"))
    }
    func testNeverInventUnknownCadenceDates() {
        XCTAssertEqual(SubscriptionForecast.dates(from: .now, frequency: "Other").count, 1)
    }
}
