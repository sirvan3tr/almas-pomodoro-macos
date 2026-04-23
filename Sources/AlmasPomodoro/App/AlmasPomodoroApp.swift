import AppKit

@main
@MainActor
struct AlmasPomodoroApp {
    static func main() {
        // argv[0] is the binary path; drop it and any Launch Services cruft.
        let args = Array(CommandLine.arguments.dropFirst())
            .filter { !$0.hasPrefix("-psn_") }

        if !args.isEmpty {
            // CLI mode: the binary is acting as a client. We talk to a
            // running GUI instance over CFMessagePort and exit.
            exit(CLIRunner.run(argv: args))
        }

        // GUI mode: register as a menu-bar-only accessory app.
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}
