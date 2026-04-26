import XCTest
@testable import AlmasPomodoro

final class ArgumentParserTests: XCTestCase {

    func testNoArgsIsGuiLaunch() throws {
        XCTAssertEqual(try ArgumentParser.parse([]), .gui)
    }

    func testStripsLaunchServicesCruft() throws {
        XCTAssertEqual(try ArgumentParser.parse(["-psn_0_12345"]), .gui)
    }

    func testHelp() throws {
        XCTAssertEqual(try ArgumentParser.parse(["-h"]), .help)
        XCTAssertEqual(try ArgumentParser.parse(["--help"]), .help)
    }

    func testVersion() throws {
        XCTAssertEqual(try ArgumentParser.parse(["--version"]), .version)
    }

    func testStartWithBareMinutes() throws {
        let invocation = try ArgumentParser.parse(["25"])
        XCTAssertEqual(invocation, .command(.start(seconds: 1500, name: nil, intent: nil)))
    }

    func testStartWithMinutesSuffix() throws {
        let invocation = try ArgumentParser.parse(["25m"])
        XCTAssertEqual(invocation, .command(.start(seconds: 1500, name: nil, intent: nil)))
    }

    func testStartWithIntent() throws {
        let invocation = try ArgumentParser.parse(["25m", "-i", "Write 10 emails"])
        XCTAssertEqual(
            invocation,
            .command(.start(seconds: 1500, name: nil, intent: "Write 10 emails"))
        )
    }

    func testStartWithAsName() throws {
        let invocation = try ArgumentParser.parse(["1h30m", "--as", "Deep Work"])
        XCTAssertEqual(
            invocation,
            .command(.start(seconds: 3600 + 30 * 60, name: "Deep Work", intent: nil))
        )
    }

    func testStartRejectsMultiplePositionals() {
        XCTAssertThrowsError(try ArgumentParser.parse(["25m", "50m"]))
    }

    func testStartRejectsUnknownFlag() {
        XCTAssertThrowsError(try ArgumentParser.parse(["25m", "--nope"]))
    }

    func testStartRejectsDanglingIntent() {
        XCTAssertThrowsError(try ArgumentParser.parse(["25m", "-i"]))
    }

    func testStop() throws {
        XCTAssertEqual(try ArgumentParser.parse(["stop"]), .command(.stop))
    }

    func testStatus() throws {
        XCTAssertEqual(try ArgumentParser.parse(["status"]), .command(.status))
    }

    func testDismiss() throws {
        XCTAssertEqual(try ArgumentParser.parse(["dismiss"]), .command(.acknowledge))
    }

    func testPresetsList() throws {
        XCTAssertEqual(try ArgumentParser.parse(["presets"]), .command(.presetsList))
        XCTAssertEqual(try ArgumentParser.parse(["presets", "ls"]), .command(.presetsList))
    }

    func testPresetsAdd() throws {
        let inv = try ArgumentParser.parse(["presets", "add", "Deep Work", "50m"])
        XCTAssertEqual(inv, .command(.presetsAdd(name: "Deep Work", seconds: 50 * 60)))
    }

    func testPresetsAddRequiresBoth() {
        XCTAssertThrowsError(try ArgumentParser.parse(["presets", "add", "Deep Work"]))
        XCTAssertThrowsError(try ArgumentParser.parse(["presets", "add"]))
    }

    func testPresetsRemove() throws {
        XCTAssertEqual(
            try ArgumentParser.parse(["presets", "rm", "Deep Work"]),
            .command(.presetsRemove(name: "Deep Work"))
        )
        XCTAssertEqual(
            try ArgumentParser.parse(["presets", "remove", "Deep Work"]),
            .command(.presetsRemove(name: "Deep Work"))
        )
    }

    func testPresetStart() throws {
        XCTAssertEqual(
            try ArgumentParser.parse(["preset", "Pomodoro"]),
            .command(.startPreset(name: "Pomodoro", intent: nil))
        )
        XCTAssertEqual(
            try ArgumentParser.parse(["preset", "Pomodoro", "-i", "Ship the PR"]),
            .command(.startPreset(name: "Pomodoro", intent: "Ship the PR"))
        )
    }

    func testPing() throws {
        XCTAssertEqual(try ArgumentParser.parse(["ping"]), .command(.ping))
    }

    func testCompletionsForEachShell() throws {
        XCTAssertEqual(
            try ArgumentParser.parse(["completions", "zsh"]),
            .completions(.zsh)
        )
        XCTAssertEqual(
            try ArgumentParser.parse(["completions", "bash"]),
            .completions(.bash)
        )
        XCTAssertEqual(
            try ArgumentParser.parse(["completions", "fish"]),
            .completions(.fish)
        )
    }

    func testCompletionsCaseInsensitive() throws {
        XCTAssertEqual(
            try ArgumentParser.parse(["completions", "ZSH"]),
            .completions(.zsh)
        )
    }

    func testCompletionsRejectsUnknownShell() {
        XCTAssertThrowsError(try ArgumentParser.parse(["completions", "tcsh"]))
    }

    func testCompletionsRejectsMissingShell() {
        XCTAssertThrowsError(try ArgumentParser.parse(["completions"]))
    }

    func testCompletionsRejectsExtraArgs() {
        XCTAssertThrowsError(try ArgumentParser.parse(["completions", "zsh", "extra"]))
    }
}
