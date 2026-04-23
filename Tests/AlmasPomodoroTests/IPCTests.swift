import XCTest
@testable import AlmasPomodoro

final class IPCTests: XCTestCase {

    private func roundTrip<T: Codable & Equatable>(_ value: T) throws -> T {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Command

    func testPingRoundTrip() throws {
        XCTAssertEqual(try roundTrip(Command.ping), .ping)
    }

    func testStartRoundTrip() throws {
        let c = Command.start(seconds: 1500, name: "Focus", intent: "Write 10 emails")
        XCTAssertEqual(try roundTrip(c), c)
    }

    func testStartWithoutOptionals() throws {
        let c = Command.start(seconds: 300, name: nil, intent: nil)
        XCTAssertEqual(try roundTrip(c), c)
    }

    func testStartPresetRoundTrip() throws {
        let c = Command.startPreset(name: "Pomodoro", intent: "Ship")
        XCTAssertEqual(try roundTrip(c), c)
    }

    func testPresetsCommandsRoundTrip() throws {
        XCTAssertEqual(try roundTrip(Command.presetsList), .presetsList)
        XCTAssertEqual(
            try roundTrip(Command.presetsAdd(name: "Deep Work", seconds: 3000)),
            .presetsAdd(name: "Deep Work", seconds: 3000)
        )
        XCTAssertEqual(
            try roundTrip(Command.presetsRemove(name: "Deep Work")),
            .presetsRemove(name: "Deep Work")
        )
    }

    // MARK: - Response

    func testOkResponseRoundTrip() throws {
        let snap = StatusSnapshot(
            state: .running,
            preset: "Pomodoro",
            totalSeconds: 1500,
            remainingSeconds: 1234,
            intent: "Write emails"
        )
        XCTAssertEqual(try roundTrip(Response.ok(snap)), .ok(snap))
    }

    func testIdleSnapshotRoundTrip() throws {
        XCTAssertEqual(try roundTrip(Response.ok(.idle)), .ok(.idle))
    }

    func testPresetsResponseRoundTrip() throws {
        let list = [PresetInfo(name: "Focus", seconds: 1500),
                    PresetInfo(name: "Break", seconds: 300)]
        XCTAssertEqual(try roundTrip(Response.presets(list: list)), .presets(list: list))
    }

    func testErrorResponseRoundTrip() throws {
        XCTAssertEqual(
            try roundTrip(Response.error(message: "boom")),
            .error(message: "boom")
        )
    }

    // MARK: - Forward compatibility

    func testDecodeIgnoresUnknownKeys() throws {
        let raw = """
        {"type":"start","seconds":1500,"intent":"x","__futureKey__":42}
        """.data(using: .utf8)!
        let cmd = try JSONDecoder().decode(Command.self, from: raw)
        XCTAssertEqual(cmd, .start(seconds: 1500, name: nil, intent: "x"))
    }
}
