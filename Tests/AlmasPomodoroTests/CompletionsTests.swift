import XCTest
@testable import AlmasPomodoro

final class CompletionsTests: XCTestCase {

    func testZshScriptIsCompdef() {
        let s = Completions.script(for: .zsh)
        XCTAssertTrue(s.contains("#compdef almaspom"))
        XCTAssertTrue(s.contains("compdef _almaspom almaspom"))
    }

    func testBashScriptRegistersCompletion() {
        let s = Completions.script(for: .bash)
        XCTAssertTrue(s.contains("complete -F _almaspom almaspom"))
    }

    func testFishScriptUsesCompleteBuiltin() {
        let s = Completions.script(for: .fish)
        XCTAssertTrue(s.contains("complete -c almaspom"))
    }

    func testEverySubcommandIsCompletableInZsh() {
        let s = Completions.script(for: .zsh)
        for cmd in ["stop", "status", "dismiss", "preset", "presets", "ping", "completions"] {
            XCTAssertTrue(s.contains(cmd), "zsh script missing subcommand \(cmd)")
        }
    }

    func testParseShellAcceptsKnown() throws {
        XCTAssertEqual(try Completions.parseShell("zsh"), .zsh)
        XCTAssertEqual(try Completions.parseShell("BASH"), .bash)
        XCTAssertEqual(try Completions.parseShell("fish"), .fish)
    }

    func testParseShellRejectsUnknown() {
        XCTAssertThrowsError(try Completions.parseShell("powershell")) { err in
            guard case Completions.GenerateError.unknownShell(let s) = err else {
                XCTFail("expected .unknownShell, got \(err)"); return
            }
            XCTAssertEqual(s, "powershell")
        }
    }
}
