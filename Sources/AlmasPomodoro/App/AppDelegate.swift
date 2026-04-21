import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, AppActions {

    private var statusItem: NSStatusItem!
    private var renderer: StatusItemRenderer!
    private let timer = PomodoroTimer()
    private var presetStore: PresetStore!

    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            presetStore = try PresetStore()
        } catch {
            fatalErrorUI(
                title: "Unable to load presets",
                detail: String(describing: error)
            )
            NSApp.terminate(nil)
            return
        }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        renderer = StatusItemRenderer(statusItem: statusItem)

        // Rebuild menu every time it's about to open so it always reflects
        // current state + persisted presets.
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        timer.onChange = { [weak self] state in
            self?.renderer.render(state)
        }

        renderer.render(.idle)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    // MARK: - NSMenuDelegate

    func menuNeedsUpdate(_ menu: NSMenu) {
        let fresh = MenuBuilder.build(
            state: timer.state,
            presets: presetStore.presets,
            target: self
        )
        menu.removeAllItems()
        for item in fresh.items {
            fresh.removeItem(item)
            menu.addItem(item)
        }
    }

    // MARK: - AppActions

    func startPresetFromMenu(_ sender: NSMenuItem) {
        guard
            let raw = sender.representedObject as? String,
            let id = UUID(uuidString: raw),
            let preset = presetStore.presets.first(where: { $0.id == id })
        else {
            NSLog("[AlmasPomodoro] start: could not resolve preset from menu item.")
            return
        }
        timer.start(preset)
    }

    func removePresetFromMenu(_ sender: NSMenuItem) {
        guard
            let raw = sender.representedObject as? String,
            let id = UUID(uuidString: raw)
        else { return }
        do {
            _ = try presetStore.remove(id: id)
        } catch {
            fatalErrorUI(title: "Could not remove preset", detail: String(describing: error))
        }
    }

    func addCustomPreset(_ sender: Any?) {
        guard let preset = AddPresetDialog.present() else { return }
        do {
            try presetStore.append(preset)
        } catch {
            fatalErrorUI(title: "Could not save preset", detail: String(describing: error))
        }
    }

    func stopTimer(_ sender: Any?) {
        timer.stop()
    }

    func acknowledgeFinish(_ sender: Any?) {
        timer.acknowledge()
    }

    func quit(_ sender: Any?) {
        NSApp.terminate(nil)
    }

    // MARK: - Error surfacing

    private func fatalErrorUI(title: String, detail: String) {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = title
        alert.informativeText = detail
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
