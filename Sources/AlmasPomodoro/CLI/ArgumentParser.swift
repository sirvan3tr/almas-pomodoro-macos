import Foundation

/// Parses `argv` (minus argv[0]) into an `Invocation`.
///
/// Commands supported:
///
///     almaspom <duration> [-i|--intent "<text>"] [--as "<name>"]
///     almaspom preset <name> [-i|--intent "<text>"]
///     almaspom stop
///     almaspom status
///     almaspom dismiss
///     almaspom presets
///     almaspom presets add <name> <duration>
///     almaspom presets rm  <name>
///     almaspom ping
///     almaspom --help | -h
///     almaspom --version
///
/// The parser is deliberately strict — unknown flags or missing operands
/// surface as `.usage` errors. "CLI first" means bad input is loud.
enum ArgumentParser {

    enum Invocation: Equatable {
        case gui                       // no CLI intent, launch the menu-bar
        case command(Command)
        case help
        case version
        case completions(Completions.Shell)
    }

    enum ParseError: Error, Equatable, CustomStringConvertible {
        case usage(String)
        case duration(DurationParser.ParseError)
        case presetName(PresetError)
        case completions(Completions.GenerateError)

        var description: String {
            switch self {
            case .usage(let msg):  return msg
            case .duration(let e): return String(describing: e)
            case .presetName(let e): return String(describing: e)
            case .completions(let e): return String(describing: e)
            }
        }
    }

    static func parse(_ argv: [String]) throws -> Invocation {
        let args = argv.filter { !$0.hasPrefix("-psn_") } // LaunchServices cruft
        guard !args.isEmpty else { return .gui }

        // Top-level flags first.
        if args.contains("-h") || args.contains("--help") { return .help }
        if args.contains("--version") { return .version }

        // Keyword subcommands.
        switch args[0] {
        case "stop":        return .command(.stop)
        case "status":      return .command(.status)
        case "dismiss":     return .command(.acknowledge)
        case "ping":        return .command(.ping)
        case "presets":     return try parsePresets(Array(args.dropFirst()))
        case "preset":      return try parsePresetStart(Array(args.dropFirst()))
        case "completions": return try parseCompletions(Array(args.dropFirst()))
        default:
            // Positional duration + optional flags.
            return try parseStart(args)
        }
    }

    private static func parseCompletions(_ args: [String]) throws -> Invocation {
        guard let head = args.first, args.count == 1 else {
            throw ParseError.usage(
                "Usage: almaspom completions {zsh|bash|fish}"
            )
        }
        do {
            return .completions(try Completions.parseShell(head))
        } catch let e as Completions.GenerateError {
            throw ParseError.completions(e)
        }
    }

    // MARK: - Subcommand parsers

    private static func parseStart(_ args: [String]) throws -> Invocation {
        var intent: String?
        var asName: String?
        var positional: [String] = []

        var i = 0
        while i < args.count {
            let a = args[i]
            switch a {
            case "-i", "--intent":
                guard let next = args[safe: i + 1] else {
                    throw ParseError.usage("`\(a)` requires a value.")
                }
                intent = next
                i += 2
            case "--as":
                guard let next = args[safe: i + 1] else {
                    throw ParseError.usage("`--as` requires a name.")
                }
                asName = next
                i += 2
            default:
                if a.hasPrefix("-") {
                    throw ParseError.usage("Unknown option: \(a)")
                }
                positional.append(a)
                i += 1
            }
        }

        guard positional.count == 1 else {
            throw ParseError.usage(
                "Expected one duration (e.g. `25m`), got \(positional.count)."
            )
        }
        let seconds: Int
        do {
            seconds = try DurationParser.parseSeconds(positional[0])
        } catch let e as DurationParser.ParseError {
            throw ParseError.duration(e)
        }
        return .command(.start(seconds: seconds, name: asName, intent: intent))
    }

    private static func parsePresetStart(_ args: [String]) throws -> Invocation {
        var intent: String?
        var positional: [String] = []

        var i = 0
        while i < args.count {
            let a = args[i]
            switch a {
            case "-i", "--intent":
                guard let next = args[safe: i + 1] else {
                    throw ParseError.usage("`\(a)` requires a value.")
                }
                intent = next
                i += 2
            default:
                if a.hasPrefix("-") { throw ParseError.usage("Unknown option: \(a)") }
                positional.append(a)
                i += 1
            }
        }

        guard positional.count == 1 else {
            throw ParseError.usage("Usage: almaspom preset <name> [-i \"intent\"]")
        }
        return .command(.startPreset(name: positional[0], intent: intent))
    }

    private static func parsePresets(_ args: [String]) throws -> Invocation {
        guard let head = args.first else {
            return .command(.presetsList)
        }
        switch head {
        case "ls", "list":
            return .command(.presetsList)
        case "add":
            guard args.count == 3 else {
                throw ParseError.usage("Usage: almaspom presets add <name> <duration>")
            }
            let name = args[1]
            let secs: Int
            do {
                secs = try DurationParser.parseSeconds(args[2])
            } catch let e as DurationParser.ParseError {
                throw ParseError.duration(e)
            }
            return .command(.presetsAdd(name: name, seconds: secs))
        case "rm", "remove":
            guard args.count == 2 else {
                throw ParseError.usage("Usage: almaspom presets rm <name>")
            }
            return .command(.presetsRemove(name: args[1]))
        default:
            throw ParseError.usage("Unknown presets subcommand: \(head)")
        }
    }

    // MARK: - Help text

    static let helpText: String = """
    almaspom — a menu-bar Pomodoro timer, CLI-first.

    USAGE
      almaspom                              Launch (or focus) the menu-bar app.
      almaspom <duration> [options]         Start a timer.
      almaspom preset <name> [options]      Start a saved preset by name.
      almaspom stop                         Stop the running timer.
      almaspom dismiss                      Acknowledge a finished timer.
      almaspom status                       Print current state.
      almaspom presets                      List saved presets.
      almaspom presets add <name> <dur>     Add a preset.
      almaspom presets rm <name>            Remove a preset.
      almaspom ping                         Check the GUI is reachable.
      almaspom completions <shell>          Print shell-completion script.

    OPTIONS
      -i, --intent <text>    Set the session intent (e.g. "Write 10 emails").
          --as <name>        Label this ad-hoc session (shown in the menu).
      -h, --help             Show this help.
          --version          Print version.

    DURATION FORMATS
      25          25 minutes (bare integer = minutes)
      25m, 25min  25 minutes
      90s, 90sec  90 seconds
      1h          1 hour
      1h30m       1 hour 30 minutes (tokens compose)

    EXAMPLES
      almaspom 25m -i "Write 10 emails"
      almaspom 1h30m --as "Deep Work"
      almaspom preset Pomodoro -i "Ship the PR"
      almaspom presets add "Deep Work" 50m
      almaspom status
    """
}

// MARK: - Helpers

private extension Array {
    subscript(safe i: Int) -> Element? {
        indices.contains(i) ? self[i] : nil
    }
}
