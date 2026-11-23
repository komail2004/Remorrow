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

    func testEveryThreeMonthsFromEndOfJanuaryDoesNotDrift() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let anchor = calendar.date(from: DateComponents(year: 2026, month: 1, day: 31))!
        let dates = SubscriptionForecast.dates(from: anchor, frequency: "Monthly",
                                                intervalCount: 3, count: 4, calendar: calendar)
        XCTAssertEqual(dates.count, 4)
        XCTAssertEqual(calendar.component(.month, from: dates[1]), 4)
        XCTAssertEqual(calendar.component(.month, from: dates[2]), 7)
        XCTAssertEqual(calendar.component(.day, from: dates[2]), 31)
    }

    func testEveryTwoWeeksForecastAndEquivalentAmount() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let anchor = calendar.date(from: DateComponents(year: 2026, month: 11, day: 22))!
        let dates = SubscriptionForecast.dates(from: anchor, frequency: "Weekly",
                                                intervalCount: 2, count: 3, calendar: calendar)
        XCTAssertEqual(dates.count, 3)
        XCTAssertEqual(calendar.dateComponents([.day], from: dates[0], to: dates[1]).day, 14)
        XCTAssertEqual(SubscriptionForecast.monthlyEquivalent(
            amount: 20, frequency: "Weekly", intervalCount: 2)!, 20 * 26 / 12, accuracy: 0.001)
    }

    func testUnknownFrequencyIsNotFalselyProjected() {
        XCTAssertEqual(SubscriptionForecast.cadenceDescription(frequency: "Other", intervalCount: 5),
                       "Custom / unknown")
        XCTAssertNil(SubscriptionForecast.monthlyEquivalent(
            amount: 29.99, frequency: "Other", intervalCount: 5))
    }

    func testMonthlyEstimatesDoNotSumDifferentCurrencies() {
        let items = [
            SubscriptionItem(name: "US service", merchant: "", nextCharge: .now,
                             amount: 12, frequency: "Monthly", currencyCode: "USD"),
            SubscriptionItem(name: "EU service", merchant: "", nextCharge: .now,
                             amount: 10, frequency: "Monthly", currencyCode: "EUR")
        ]
        let totals = SubscriptionForecast.monthlyTotalsByCurrency(items)
        XCTAssertEqual(totals["USD"], 12)
        XCTAssertEqual(totals["EUR"], 10)
    }

    func testVerifiedUpcomingChargeIsDistinguishedFromProjection() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let anchor = calendar.date(from: DateComponents(year: 2027, month: 1, day: 31))!
        let now = calendar.date(from: DateComponents(year: 2027, month: 1, day: 1))!
        let upcoming = SubscriptionForecast.upcomingOccurrences(
            from: anchor, frequency: "Monthly", count: 3, after: now, calendar: calendar)
        XCTAssertEqual(upcoming.count, 3)
        XCTAssertEqual(upcoming[0].date, anchor)
        XCTAssertFalse(upcoming[0].isProjected)
        XCTAssertTrue(upcoming[1].isProjected)
    }

    func testPastVerifiedChargeAdvancesToProjectedRenewalWithoutDrift() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let anchor = calendar.date(from: DateComponents(year: 2026, month: 1, day: 31))!
        let now = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1))!
        let upcoming = SubscriptionForecast.upcomingOccurrences(
            from: anchor, frequency: "Monthly", count: 2, after: now, calendar: calendar)
        XCTAssertEqual(upcoming.count, 2)
        XCTAssertEqual(calendar.component(.month, from: upcoming[0].date), 3)
        XCTAssertEqual(calendar.component(.day, from: upcoming[0].date), 31)
        XCTAssertTrue(upcoming.allSatisfy(\.isProjected))
    }

    func testExpiredUnknownCadenceDoesNotInventRenewal() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let past = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let now = calendar.date(from: DateComponents(year: 2026, month: 11, day: 1))!
        XCTAssertTrue(SubscriptionForecast.upcomingOccurrences(
            from: past, frequency: "Other", after: now, calendar: calendar).isEmpty)
    }

    func testDSTCrossingWeeklyScheduleKeepsLocalWallClockTime() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        let anchor = calendar.date(from: DateComponents(year: 2026, month: 10, day: 25, hour: 9))!
        let now = calendar.date(from: DateComponents(year: 2026, month: 11, day: 2))!
        let upcoming = SubscriptionForecast.upcomingOccurrences(
            from: anchor, frequency: "Weekly", after: now, calendar: calendar)
        XCTAssertFalse(upcoming.isEmpty)
        XCTAssertEqual(calendar.component(.hour, from: upcoming[0].date), 9)
    }
}
