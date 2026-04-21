import AppKit

/// Builds the NSMenu shown when the user clicks the status item.
///
/// This is a pure constructor: given the current state + presets + a target
/// that knows how to handle selectors, it returns a fresh NSMenu. No mutation
/// of existing menus — we rebuild on every open (accretion-friendly and
/// simpler than managing incremental diffs).
@MainActor
enum MenuBuilder {
    static func build(
        state: TimerState,
        presets: [Preset],
        target: AnyObject
    ) -> NSMenu {
        let menu = NSMenu()

        menu.addItem(headerItem(for: state))
        menu.addItem(.separator())

        menu.addItem(sectionLabel("Start"))
        for preset in presets {
            let item = NSMenuItem(
                title: "\(preset.name)  —  \(Formatting.shortDuration(preset.seconds))",
                action: #selector(AppActions.startPresetFromMenu(_:)),
                keyEquivalent: ""
            )
            item.representedObject = preset.id.uuidString
            item.target = target
            menu.addItem(item)
        }

        menu.addItem(.separator())
        menu.addItem(sectionLabel("Presets"))

        let add = NSMenuItem(
            title: "Add custom timer…",
            action: #selector(AppActions.addCustomPreset(_:)),
            keyEquivalent: "n"
        )
        add.target = target
        menu.addItem(add)

        if !presets.isEmpty {
            let removeMenu = NSMenu(title: "Remove")
            for preset in presets {
                let item = NSMenuItem(
                    title: "\(preset.name)  —  \(Formatting.shortDuration(preset.seconds))",
                    action: #selector(AppActions.removePresetFromMenu(_:)),
                    keyEquivalent: ""
                )
                item.representedObject = preset.id.uuidString
                item.target = target
                removeMenu.addItem(item)
            }
            let removeItem = NSMenuItem(title: "Remove preset", action: nil, keyEquivalent: "")
            removeItem.submenu = removeMenu
            menu.addItem(removeItem)
        }

        menu.addItem(.separator())

        switch state {
        case .idle:
            break
        case .running:
            let stop = NSMenuItem(
                title: "Stop timer",
                action: #selector(AppActions.stopTimer(_:)),
                keyEquivalent: "."
            )
            stop.target = target
            menu.addItem(stop)
        case .finished:
            let ack = NSMenuItem(
                title: "Dismiss",
                action: #selector(AppActions.acknowledgeFinish(_:)),
                keyEquivalent: "\r"
            )
            ack.target = target
            menu.addItem(ack)
        }

        menu.addItem(.separator())
        let quit = NSMenuItem(
            title: "Quit Almas Pomodoro",
            action: #selector(AppActions.quit(_:)),
            keyEquivalent: "q"
        )
        quit.target = target
        menu.addItem(quit)

        return menu
    }

    private static func headerItem(for state: TimerState) -> NSMenuItem {
        let text: String
        switch state {
        case .idle:
            text = "Almas Pomodoro — idle"
        case .running(let preset, let remaining):
            text = "\(preset.name) — \(Formatting.clock(remaining)) remaining"
        case .finished(let preset):
            text = "\(preset.name) — finished"
        }
        let item = NSMenuItem(title: text, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private static func sectionLabel(_ text: String) -> NSMenuItem {
        let item = NSMenuItem(title: text, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }
}

/// The selector surface the menu binds to. Implemented by `AppDelegate`.
@MainActor
@objc protocol AppActions: AnyObject {
    func startPresetFromMenu(_ sender: NSMenuItem)
    func removePresetFromMenu(_ sender: NSMenuItem)
    func addCustomPreset(_ sender: Any?)
    func stopTimer(_ sender: Any?)
    func acknowledgeFinish(_ sender: Any?)
    func quit(_ sender: Any?)
}
