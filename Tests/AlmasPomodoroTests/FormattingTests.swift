import XCTest
@testable import AlmasPomodoro

final class FormattingTests: XCTestCase {
    func testClockZero() { XCTAssertEqual(Formatting.clock(0), "00:00") }
    func testClockUnderMinute() { XCTAssertEqual(Formatting.clock(9), "00:09") }
    func testClockMinuteExact() { XCTAssertEqual(Formatting.clock(60), "01:00") }
    func testClockMixed() { XCTAssertEqual(Formatting.clock(25 * 60 + 7), "25:07") }
    func testClockLarge() { XCTAssertEqual(Formatting.clock(90 * 60), "90:00") }

    func testShortDurationMinutes() { XCTAssertEqual(Formatting.shortDuration(25 * 60), "25m") }
    func testShortDurationSeconds() { XCTAssertEqual(Formatting.shortDuration(45), "45s") }
    func testShortDurationMixed() { XCTAssertEqual(Formatting.shortDuration(3 * 60 + 10), "3m10s") }
}
