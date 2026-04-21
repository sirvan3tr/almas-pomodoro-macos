import XCTest
@testable import AlmasPomodoro

final class PresetTests: XCTestCase {
    func testValidPreset() throws {
        let p = try Preset(name: "Deep Work", seconds: 50 * 60)
        XCTAssertEqual(p.name, "Deep Work")
        XCTAssertEqual(p.seconds, 3000)
    }

    func testTrimsWhitespaceInName() throws {
        let p = try Preset(name: "  Focus  ", seconds: 60)
        XCTAssertEqual(p.name, "Focus")
    }

    func testRejectsEmptyName() {
        XCTAssertThrowsError(try Preset(name: "   ", seconds: 60)) { err in
            XCTAssertEqual(err as? PresetError, .emptyName)
        }
    }

    func testRejectsNonPositiveDuration() {
        XCTAssertThrowsError(try Preset(name: "x", seconds: 0)) { err in
            XCTAssertEqual(err as? PresetError, .nonPositiveDuration(0))
        }
        XCTAssertThrowsError(try Preset(name: "x", seconds: -5)) { err in
            XCTAssertEqual(err as? PresetError, .nonPositiveDuration(-5))
        }
    }

    func testRejectsExcessiveDuration() {
        let s = Preset.maxSeconds + 1
        XCTAssertThrowsError(try Preset(name: "x", seconds: s)) { err in
            XCTAssertEqual(err as? PresetError, .tooLong(s))
        }
    }
}
