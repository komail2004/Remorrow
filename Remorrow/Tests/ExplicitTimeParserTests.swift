import XCTest
@testable import Remorrow

final class ExplicitTimeParserTests: XCTestCase {
    func testCommonEveningTime() {
        let result = ExplicitTimeParser.parse(in: "Dinner with ruby at 7pm")
        XCTAssertEqual(result?.hour, 19)
        XCTAssertEqual(result?.minute, 0)
        XCTAssertEqual(result?.evidence.lowercased(), "7pm")
    }

    func testStandaloneMeridiemWithoutAt() {
        XCTAssertEqual(ExplicitTimeParser.parse(in: "Dinner with Ruby 7 PM")?.hour, 19)
        XCTAssertEqual(ExplicitTimeParser.parse(in: "Meet Alex at 7:45 p.m.")?.minute, 45)
        XCTAssertEqual(ExplicitTimeParser.parse(in: "Call at 7am")?.hour, 7)
    }

    func testNoonMidnightAndTwelveHourEdgeCases() {
        XCTAssertEqual(ExplicitTimeParser.parse(in: "Dinner at 12 PM")?.hour, 12)
        XCTAssertEqual(ExplicitTimeParser.parse(in: "Call at 12am")?.hour, 0)
        XCTAssertEqual(ExplicitTimeParser.parse(in: "Meeting at noon")?.hour, 12)
        XCTAssertEqual(ExplicitTimeParser.parse(in: "Flight at midnight")?.hour, 0)
    }

    func testExplicitTwentyFourHourTime() {
        let result = ExplicitTimeParser.parse(in: "Meeting at 19:35")
        XCTAssertEqual(result?.hour, 19)
        XCTAssertEqual(result?.minute, 35)
    }

    func testDoNotTreatDateNumbersOrBareHourAsVerifiedClockTime() {
        XCTAssertNil(ExplicitTimeParser.parse(in: "Dinner with Rubi on November 20, 2026"))
        XCTAssertNil(ExplicitTimeParser.parse(in: "Dinner at 7"))
        XCTAssertNil(ExplicitTimeParser.parse(in: "We have 7 assignments"))
        XCTAssertNil(ExplicitTimeParser.parse(in: "Dinner at 13pm"))
        XCTAssertNil(ExplicitTimeParser.parse(in: "Meeting at 25:90"))
    }

    func testNoDateStillKeepsSevenPMInPicker() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 11,
                                                      day: 9, hour: 20, minute: 37))!
        let result = ExplicitTimeParser.suggestedPickerDate(
            hour: 19, minute: 0, now: now, calendar: calendar)
        XCTAssertEqual(calendar.component(.day, from: result), 10)
        XCTAssertEqual(calendar.component(.hour, from: result), 19)
        XCTAssertEqual(calendar.component(.minute, from: result), 0)
    }

    func testEarlierTodayUsesTodayButStillRequiresDateReview() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 11,
                                                      day: 9, hour: 15, minute: 0))!
        let result = ExplicitTimeParser.suggestedPickerDate(
            hour: 19, minute: 0, now: now, calendar: calendar)
        XCTAssertEqual(calendar.component(.day, from: result), 9)
        XCTAssertEqual(calendar.component(.hour, from: result), 19)
    }
}
