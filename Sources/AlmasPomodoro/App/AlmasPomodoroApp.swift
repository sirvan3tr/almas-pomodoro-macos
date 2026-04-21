import AppKit

@main
@MainActor
struct AlmasPomodoroApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        // Menu-bar-only: no Dock icon, no application menu bar.
        app.setActivationPolicy(.accessory)
        app.run()
    }
}
