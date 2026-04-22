import AppKit

/// Builds the NSMenu shown when the user clicks the status item.
///
/// Pure constructor: `(state, presets, target) → NSMenu`. We rebuild from
/// scratch on every open rather than diffing, which keeps the rendering
/// code honest — the menu is always a function of the current state.
///
/// Visual language (consistent across every item):
///
///   * Section headers     — `NSMenuItem.sectionHeader(title:)` (macOS 14+)
///   * Per-item icons      — SF Symbols from `Icons`, palette-coloured
///   * Header line         — preset + remaining time, bold attributed title
///   * Intent line         — italic secondary label under the header
///
@MainActor
enum MenuBuilder {

    static func build(
        state: TimerState,
        presets: [Preset],
        target: AnyObject
    ) -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false

        // Header block
        for item in headerItems(for: state) {
            menu.addItem(item)
        }

        // State-specific primary action comes first so the default action
        // is a single glance away from the header.
        switch state {
        case .idle:
            break
        case .running:
            menu.addItem(.separator())
            menu.addItem(
                action(
                    title: "Stop timer",
                    icon: Icons.stop(),
                    keyEquivalent: ".",
                    selector: #selector(AppActions.stopTimer(_:)),
                    target: target
                )
            )
        case .finished:
            menu.addItem(.separator())
            menu.addItem(
                action(
                    title: "Dismiss",
                    icon: Icons.dismiss(),
                    keyEquivalent: "\r",
                    selector: #selector(AppActions.acknowledgeFinish(_:)),
                    target: target
                )
            )
        }

        // Start section
        menu.addItem(.sectionHeader(title: state.isIdle ? "Start session" : "Start another"))
        for preset in presets {
            let item = NSMenuItem(
                title: preset.name,
                action: #selector(AppActions.startPresetFromMenu(_:)),
                keyEquivalent: ""
            )
            item.image = Icons.play()
            item.target = target
            item.representedObject = preset.id.uuidString
            item.attributedTitle = startRowTitle(preset: preset)
            menu.addItem(item)
        }

        // Presets section
        menu.addItem(.sectionHeader(title: "Presets"))

        let add = action(
            title: "Add custom timer…",
            icon: Icons.add(),
            keyEquivalent: "n",
            selector: #selector(AppActions.addCustomPreset(_:)),
            target: target
        )
        menu.addItem(add)

        if !presets.isEmpty {
            let removeMenu = NSMenu(title: "Remove")
            for preset in presets {
                let item = NSMenuItem(
                    title: "\(preset.name)  ·  \(Formatting.shortDuration(preset.seconds))",
                    action: #selector(AppActions.removePresetFromMenu(_:)),
                    keyEquivalent: ""
                )
                item.image = Icons.remove()
                item.representedObject = preset.id.uuidString
                item.target = target
                removeMenu.addItem(item)
            }
            let removeItem = NSMenuItem(title: "Remove preset", action: nil, keyEquivalent: "")
            removeItem.image = Icons.remove()
            removeItem.submenu = removeMenu
            menu.addItem(removeItem)
        }

        // Footer
        menu.addItem(.separator())
        menu.addItem(
            action(
                title: "Quit Almas Pomodoro",
                icon: Icons.quit(),
                keyEquivalent: "q",
                selector: #selector(AppActions.quit(_:)),
                target: target
            )
        )

        return menu
    }

    // MARK: - Header

    /// Header lines. Either one (idle) or two (running/finished with intent).
    private static func headerItems(for state: TimerState) -> [NSMenuItem] {
        switch state {
        case .idle:
            return [
                disabledAttributedItem(
                    attributed: headerAttributed(
                        title: "Almas Pomodoro",
                        subtitle: "Ready"
                    ),
                    icon: Icons.tomato()
                )
            ]
        case .running(let session, let remaining):
            let header = disabledAttributedItem(
                attributed: headerAttributed(
                    title: session.preset.name,
                    subtitle: "\(Formatting.clock(remaining)) remaining"
                ),
                icon: Icons.tomato()
            )
            return [header] + intentRows(for: session)
        case .finished(let session):
            let header = disabledAttributedItem(
                attributed: headerAttributed(
                    title: session.preset.name,
                    subtitle: "Finished"
                ),
                icon: Icons.dismiss()
            )
            return [header] + intentRows(for: session)
        }
    }

    private static func intentRows(for session: Session) -> [NSMenuItem] {
        guard let intent = session.intent else { return [] }
        let maxGlyphs = 80
        let display = intent.count > maxGlyphs
            ? String(intent.prefix(maxGlyphs)) + "…"
            : intent

        let text = NSMutableAttributedString()
        text.append(NSAttributedString(
            string: display,
            attributes: [
                .font: NSFont.systemFont(ofSize: 12, weight: .regular)
                    .italic(),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
        ))

        let item = NSMenuItem(title: display, action: nil, keyEquivalent: "")
        item.attributedTitle = text
        item.image = Icons.intent()
        item.isEnabled = false
        return [item]
    }

    // MARK: - Building blocks

    private static func action(
        title: String,
        icon: NSImage?,
        keyEquivalent: String,
        selector: Selector,
        target: AnyObject
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: selector, keyEquivalent: keyEquivalent)
        item.image = icon
        item.target = target
        return item
    }

    private static func disabledAttributedItem(
        attributed: NSAttributedString,
        icon: NSImage?
    ) -> NSMenuItem {
        let item = NSMenuItem(title: attributed.string, action: nil, keyEquivalent: "")
        item.attributedTitle = attributed
        item.image = icon
        item.isEnabled = false
        return item
    }

    private static func headerAttributed(title: String, subtitle: String) -> NSAttributedString {
        let result = NSMutableAttributedString()
        result.append(NSAttributedString(
            string: title,
            attributes: [
                .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
                .foregroundColor: NSColor.labelColor
            ]
        ))
        result.append(NSAttributedString(
            string: "  ·  \(subtitle)",
            attributes: [
                .font: NSFont.systemFont(ofSize: 12, weight: .regular),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
        ))
        return result
    }

    private static func startRowTitle(preset: Preset) -> NSAttributedString {
        let result = NSMutableAttributedString()
        result.append(NSAttributedString(
            string: preset.name,
            attributes: [
                .font: NSFont.systemFont(ofSize: 13, weight: .medium),
                .foregroundColor: NSColor.labelColor
            ]
        ))
        result.append(NSAttributedString(
            string: "  ·  \(Formatting.shortDuration(preset.seconds))",
            attributes: [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
        ))
        return result
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

// MARK: - Small helpers

private extension TimerState {
    var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }
}

private extension NSFont {
    /// Best-effort italic variant — falls back to the original font if the
    /// system refuses (SF Pro's regular weight honours this).
    func italic() -> NSFont {
        let descriptor = fontDescriptor.withSymbolicTraits(.italic)
        return NSFont(descriptor: descriptor, size: pointSize) ?? self
    }
}
