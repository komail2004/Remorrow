import XCTest
@testable import Remorrow

final class PlanConflictDetectorTests: XCTestCase {
    private let time = Date(timeIntervalSince1970: 1805662800)

    private func plan(_ title: String, minutes: Int = 0,
                      kind: String = "calendarEvent") -> SavedPlanRecord {
        SavedPlanRecord(id: UUID(), title: title,
                        dueAt: time.addingTimeInterval(Double(minutes * 60)),
                        kind: kind)
    }

    private func conflicts(_ title: String, minutes: Int = 0,
                           kind: String = "calendarEvent",
                           previous: [SavedPlanRecord]) -> [PlanConflict] {
        PlanConflictDetector.find(title: title,
                                  dueAt: time.addingTimeInterval(Double(minutes * 60)),
                                  kind: kind, among: previous)
    }

    func testIdenticalEventAtSameTime() {
        let saved = plan("Dinner with Rubi")
        let result = conflicts("Dinner with Rubi", previous: [saved])
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.reason, .likelyDuplicate)
    }

    func testRephrasedDinnerWithRubiAtSameTimeIsDuplicate() {
        let saved = plan("Dinner with Rubi")
        let result = conflicts("Rubi will have dinner with me", previous: [saved])
        XCTAssertEqual(result.first?.reason, .likelyDuplicate)
    }

    func testRubiAndRubySpellingVariants() {
        let saved = plan("Dinner with Rubi")
        XCTAssertEqual(conflicts("Have supper with Ruby", previous: [saved]).first?.reason,
                       .likelyDuplicate)
    }

    func testSameDinnerDifferentTimeIsPossibleDuplicateNotCertain() {
        let saved = plan("Dinner with Rubi", minutes: -480)
        let result = conflicts("Rubi will have dinner with me", previous: [saved])
        XCTAssertEqual(result.first?.reason, .samePlanDifferentTime)
    }

    func testDifferentPersonAtExactlySameTimeIsAllowedButFlagged() {
        let saved = plan("Dinner with Alex")
        XCTAssertEqual(conflicts("Dinner with Rubi", previous: [saved]).first?.reason,
                       .overlappingEvent)
    }

    func testTwoUnrelatedEventsMayOverlap() {
        let saved = plan("Doctor appointment")
        XCTAssertEqual(conflicts("Dinner with Rubi", previous: [saved]).first?.reason,
                       .overlappingEvent)
    }

    func testNoConflictWhenSeparatedByMoreThanAnHour() {
        let saved = plan("Meeting with Alex", minutes: -90)
        XCTAssertTrue(conflicts("Dinner with Rubi", previous: [saved]).isEmpty)
    }

    func testASecondReminderAtSameTimeIsNotBlocked() {
        let saved = plan("Submit biology assignment", kind: "reminder")
        XCTAssertTrue(conflicts("Pay electric bill", kind: "reminder",
                                previous: [saved]).isEmpty)
    }

    func testDuplicateRemindersStillDetected() {
        let saved = plan("Submit biology assignment", kind: "reminder")
        XCTAssertEqual(conflicts("Submit biology assignment", kind: "reminder",
                                 previous: [saved]).first?.reason, .likelyDuplicate)
    }

    func testEventsAndRemindersDoNotConflictWithOneAnother() {
        let saved = plan("Dinner with Rubi", kind: "reminder")
        XCTAssertTrue(conflicts("Dinner with Rubi", previous: [saved]).isEmpty)
    }

    func testSameDinnerNextWeekIsNotClassifiedAsDuplicate() {
        let saved = plan("Dinner with Rubi", minutes: -7 * 24 * 60)
        XCTAssertTrue(conflicts("Dinner with Rubi", previous: [saved]).isEmpty)
    }

    func testDifferentSubjectsWithSameGenericCategoryAreNotDuplicates() {
        let saved = plan("Biology presentation")
        XCTAssertEqual(conflicts("Physics presentation", previous: [saved]).first?.reason,
                       .overlappingEvent)
    }

    func testManyConflictsPrioritizeSamePlan() {
        let unrelated = plan("Appointment with Dr. Smith")
        let duplicate = plan("Rubi will have dinner with me")
        let result = conflicts("Dinner with Rubi", previous: [unrelated, duplicate])
        XCTAssertEqual(result.first?.record.id, duplicate.id)
        XCTAssertEqual(result.last?.reason, .overlappingEvent)
    }

    func testNearbySameEventWithinFiveMinutes() {
        let saved = plan("Dinner with Rubi", minutes: 4)
        XCTAssertEqual(conflicts("Dinner with Rubi", previous: [saved]).first?.reason,
                       .likelyDuplicate)
    }

    func testSubjectMattersEvenWithWordOrderChanges() {
        let saved = plan("Dinner with Rubi")
        XCTAssertEqual(conflicts("Dinner with Alex", previous: [saved]).first?.reason,
                       .overlappingEvent)
    }

    func testExistingTriplicateProducesTwoSuggestedExtraCopies() {
        let items = [
            plan("Dinner with Rubi"),
            plan("Rubi will have dinner with me"),
            plan("Dinner with Ruby", minutes: -480)
        ]
        let pairs = PlanConflictDetector.existingDuplicates(in: items)
        XCTAssertEqual(pairs.count, 2)
        XCTAssertEqual(pairs[0].original.id, items[0].id)
        XCTAssertEqual(pairs[0].possibleExtra.id, items[1].id)
        XCTAssertEqual(pairs[1].original.id, items[0].id)
        XCTAssertEqual(pairs[1].reason, .samePlanDifferentTime)
    }

    func testExistingSeparateEventsAtSameTimeNotMisnamedDuplicates() {
        let items = [
            plan("Dinner with Rubi"),
            plan("Dinner with Alex"),
            plan("Dentist appointment")
        ]
        XCTAssertTrue(PlanConflictDetector.existingDuplicates(in: items).isEmpty)
    }
}
