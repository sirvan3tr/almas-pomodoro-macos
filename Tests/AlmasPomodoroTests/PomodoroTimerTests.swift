import XCTest
@testable import AlmasPomodoro

final class PomodoroTimerTests: XCTestCase {

    func testStartsInIdle() {
        let t = PomodoroTimer()
        XCTAssertEqual(t.state, .idle)
    }

    func testStartTransitionsToRunning() throws {
        let t = PomodoroTimer()
        let preset = try Preset(name: "x", seconds: 60)
        t.start(preset)
        guard case .running(let session, let r) = t.state else {
            return XCTFail("expected running, got \(t.state)")
        }
        XCTAssertEqual(session.preset, preset)
        XCTAssertNil(session.intent)
        XCTAssertEqual(r, 60)
    }

    func testStartWithSessionCarriesIntent() throws {
        let t = PomodoroTimer()
        let preset = try Preset(name: "Focus", seconds: 10)
        let session = try Session(preset: preset, intent: "Write 10 emails")
        t.start(session)
        guard case .running(let running, _) = t.state else {
            return XCTFail("expected running, got \(t.state)")
        }
        XCTAssertEqual(running.intent, "Write 10 emails")
    }

    func testTickDecrementsRemaining() throws {
        let t = PomodoroTimer()
        let preset = try Preset(name: "x", seconds: 10)
        let start = Date(timeIntervalSince1970: 1_000_000)
        t.start(preset, now: start)
        t.tick(now: start.addingTimeInterval(3))
        guard case .running(_, let r) = t.state else {
            return XCTFail("expected running, got \(t.state)")
        }
        XCTAssertEqual(r, 7)
    }

    func testTickToZeroFinishes() throws {
        let t = PomodoroTimer()
        let preset = try Preset(name: "x", seconds: 5)
        let start = Date(timeIntervalSince1970: 1_000_000)
        t.start(preset, now: start)
        t.tick(now: start.addingTimeInterval(5.001))
        XCTAssertTrue(t.state.isFinished)
    }

    func testStopReturnsToIdle() throws {
        let t = PomodoroTimer()
        let preset = try Preset(name: "x", seconds: 10)
        t.start(preset)
        t.stop()
        XCTAssertEqual(t.state, .idle)
    }

    func testAcknowledgeOnlyWorksWhenFinished() throws {
        let t = PomodoroTimer()
        t.acknowledge()
        XCTAssertEqual(t.state, .idle)

        let preset = try Preset(name: "x", seconds: 1)
        let start = Date(timeIntervalSince1970: 1_000_000)
        t.start(preset, now: start)
        t.tick(now: start.addingTimeInterval(2))
        XCTAssertTrue(t.state.isFinished)
        t.acknowledge()
        XCTAssertEqual(t.state, .idle)
    }

    func testOnChangeFires() throws {
        let t = PomodoroTimer()
        var seen: [TimerState] = []
        t.onChange = { seen.append($0) }
        let preset = try Preset(name: "x", seconds: 2)
        let start = Date(timeIntervalSince1970: 1_000_000)
        t.start(preset, now: start)
        t.tick(now: start.addingTimeInterval(1))
        t.tick(now: start.addingTimeInterval(2.5))
        XCTAssertFalse(seen.isEmpty)
        XCTAssertTrue(seen.last?.isFinished ?? false)
    }
}
