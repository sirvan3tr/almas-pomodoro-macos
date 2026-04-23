import XCTest
@testable import AlmasPomodoro

final class DurationParserTests: XCTestCase {

    func testBareIntegerIsMinutes() throws {
        XCTAssertEqual(try DurationParser.parseSeconds("25"), 25 * 60)
        XCTAssertEqual(try DurationParser.parseSeconds(" 25 "), 25 * 60)
    }

    func testMinuteSuffixes() throws {
        for s in ["25m", "25min", "25mins", "25minute", "25minutes"] {
            XCTAssertEqual(try DurationParser.parseSeconds(s), 25 * 60, "failed on \(s)")
        }
    }

    func testSecondSuffixes() throws {
        for s in ["90s", "90sec", "90secs", "90second", "90seconds"] {
            XCTAssertEqual(try DurationParser.parseSeconds(s), 90, "failed on \(s)")
        }
    }

    func testHourSuffixes() throws {
        for s in ["1h", "1hr", "1hrs", "1hour", "1hours"] {
            XCTAssertEqual(try DurationParser.parseSeconds(s), 3600, "failed on \(s)")
        }
    }

    func testCompoundDuration() throws {
        XCTAssertEqual(try DurationParser.parseSeconds("1h30m"), 3600 + 30 * 60)
        XCTAssertEqual(try DurationParser.parseSeconds("1h30m15s"), 3600 + 30 * 60 + 15)
        XCTAssertEqual(try DurationParser.parseSeconds("25min30sec"), 25 * 60 + 30)
    }

    func testCaseInsensitive() throws {
        XCTAssertEqual(try DurationParser.parseSeconds("25M"), 25 * 60)
        XCTAssertEqual(try DurationParser.parseSeconds("1H30M"), 3600 + 30 * 60)
    }

    func testRejectsEmpty() {
        XCTAssertThrowsError(try DurationParser.parseSeconds("")) { err in
            XCTAssertEqual(err as? DurationParser.ParseError, .empty)
        }
        XCTAssertThrowsError(try DurationParser.parseSeconds("   ")) { err in
            XCTAssertEqual(err as? DurationParser.ParseError, .empty)
        }
    }

    func testRejectsNonPositive() {
        XCTAssertThrowsError(try DurationParser.parseSeconds("0")) { err in
            XCTAssertEqual(err as? DurationParser.ParseError, .nonPositive)
        }
        XCTAssertThrowsError(try DurationParser.parseSeconds("0m")) { err in
            XCTAssertEqual(err as? DurationParser.ParseError, .nonPositive)
        }
    }

    func testRejectsUnknownUnit() {
        XCTAssertThrowsError(try DurationParser.parseSeconds("25x"))
        XCTAssertThrowsError(try DurationParser.parseSeconds("abc"))
        XCTAssertThrowsError(try DurationParser.parseSeconds("1h30x"))
    }

    func testRejectsExcessiveDuration() {
        XCTAssertThrowsError(try DurationParser.parseSeconds("25h"))
    }
}
