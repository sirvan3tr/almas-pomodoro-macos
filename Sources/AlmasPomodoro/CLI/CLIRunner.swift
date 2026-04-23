import Foundation

/// Owns the CLI side of the binary: parses argv, round-trips a command
/// through `CLIClient`, prints a human-friendly result, and returns an
/// exit code.
///
/// `run(argv:)` is pure-ish — it takes its inputs and returns a code —
/// so tests can drive it end-to-end without touching `exit()`.
enum CLIRunner {

    /// Version surfaced by `almaspom --version`. Bumped by hand at releases.
    static let version = "0.2.0"

    /// Returns a process exit code. `0` on success, non-zero on failure.
    static func run(argv: [String]) -> Int32 {
        let invocation: ArgumentParser.Invocation
        do {
            invocation = try ArgumentParser.parse(argv)
        } catch let e as ArgumentParser.ParseError {
            fputs("error: \(e)\n", stderr)
            fputs("Run `almaspom --help` for usage.\n", stderr)
            return 2
        } catch {
            fputs("error: \(error)\n", stderr)
            return 2
        }

        switch invocation {
        case .gui:
            // Shouldn't hit this path — the caller only invokes us for
            // CLI intents. Treat it as a no-op success.
            return 0
        case .help:
            print(ArgumentParser.helpText)
            return 0
        case .version:
            print("almaspom \(version)")
            return 0
        case .command(let command):
            return dispatch(command)
        }
    }

    // MARK: - Command dispatch

    private static func dispatch(_ command: Command) -> Int32 {
        let response: Response
        do {
            response = try CLIClient.send(command, autoLaunch: autoLaunchPolicy(for: command))
        } catch let e as CLIClient.ClientError {
            if case .guiUnreachable = e, case .status = command {
                // `status` with no server = "idle, not running" is a fine answer.
                printStatus(.idle)
                return 0
            }
            fputs("error: \(e)\n", stderr)
            return 1
        } catch {
            fputs("error: \(error)\n", stderr)
            return 1
        }

        return emit(response, for: command)
    }

    private static func autoLaunchPolicy(for command: Command) -> Bool {
        switch command {
        case .status, .ping: return false   // read-only: don't spin up GUI
        default:             return true    // state-changing: ensure server is up
        }
    }

    // MARK: - Output

    private static func emit(_ response: Response, for command: Command) -> Int32 {
        switch response {
        case .ok(let snapshot):
            printStatus(snapshot)
            return 0
        case .presets(let list):
            printPresets(list)
            return 0
        case .error(let message):
            fputs("error: \(message)\n", stderr)
            return 1
        }
    }

    private static func printStatus(_ snapshot: StatusSnapshot) {
        switch snapshot.state {
        case .idle:
            print("idle")
        case .running:
            let preset = snapshot.preset ?? "Timer"
            let remaining = snapshot.remainingSeconds ?? 0
            let clock = Formatting.clock(max(0, remaining))
            var line = "running  \(preset)  \(clock) remaining"
            if let intent = snapshot.intent {
                line += "\n     intent: \(intent)"
            }
            print(line)
        case .finished:
            let preset = snapshot.preset ?? "Timer"
            var line = "finished  \(preset)"
            if let intent = snapshot.intent {
                line += "\n     intent: \(intent)"
            }
            print(line)
        }
    }

    private static func printPresets(_ list: [PresetInfo]) {
        if list.isEmpty {
            print("(no presets)")
            return
        }
        let nameWidth = list.map(\.name.count).max() ?? 0
        for preset in list {
            let padding = String(repeating: " ", count: max(0, nameWidth - preset.name.count))
            print("\(preset.name)\(padding)  \(Formatting.shortDuration(preset.seconds))")
        }
    }
}
