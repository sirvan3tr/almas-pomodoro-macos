import XCTest
@testable import AlmasPomodoro

final class SessionTests: XCTestCase {

    private func preset() throws -> Preset {
        try Preset(name: "Focus", seconds: 25 * 60)
    }

    func testKeepsNonEmptyIntent() throws {
        let s = try Session(preset: preset(), intent: "Write 10 emails")
        XCTAssertEqual(s.intent, "Write 10 emails")
    }

    func testTrimsWhitespaceInIntent() throws {
        let s = try Session(preset: preset(), intent: "   Ship the PR   ")
        XCTAssertEqual(s.intent, "Ship the PR")
    }

    func testNilIntentStaysNil() throws {
        let s = try Session(preset: preset(), intent: nil)
        XCTAssertNil(s.intent)
    }

    func testWhitespaceOnlyCollapsesToNil() throws {
        let s = try Session(preset: preset(), intent: "   \n\t ")
        XCTAssertNil(s.intent)
    }

    func testRejectsOverlongIntent() {
        let tooLong = String(repeating: "x", count: Session.maxIntentLength + 1)
        XCTAssertThrowsError(try Session(preset: try preset(), intent: tooLong)) { err in
            guard case SessionError.intentTooLong(let n) = err else {
                return XCTFail("expected intentTooLong, got \(err)")
            }
            XCTAssertEqual(n, Session.maxIntentLength + 1)
        }
    }

    func testNormalizeIsTheSingleValidationPath() throws {
        XCTAssertNil(try Session.normalize(intent: nil))
        XCTAssertNil(try Session.normalize(intent: ""))
        XCTAssertNil(try Session.normalize(intent: "   "))
        XCTAssertEqual(try Session.normalize(intent: "  focus  "), "focus")
    }
}
