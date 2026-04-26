import AppKit

/// Single source of truth for every SF Symbol the app shows. Each icon is
/// addressed by a semantic role, not a symbol name — so the visual language
/// is consistent and one edit changes every place a concept is rendered.
///
/// Everything returns a ready-to-display `NSImage`. Palette-coloured icons
/// (play/stop/add/remove/etc.) keep `isTemplate = false` so their colours
/// survive into menus. Monochrome/template icons stay neutral for the
/// status-bar button, which inherits its tint from `contentTintColor`.
@MainActor
enum Icons {

    // MARK: - Status-bar (template, tint-driven)

    static func idleStatusBar() -> NSImage? {
        let img = NSImage(
            systemSymbolName: "timer",
            accessibilityDescription: "Almas Pomodoro — idle"
        )?.withSymbolConfiguration(
            .init(pointSize: 14, weight: .semibold)
        )
        img?.isTemplate = true
        return img
    }

    /// Variable-fill timer icon for use inside the running pill.
    /// `progress` is `remaining / total`, clamped to 0…1, so the ring
    /// drains as the session counts down.
    static func runningPill(progress: Double) -> NSImage? {
        let clamped = max(0.0, min(1.0, progress))
        let img = NSImage(
            systemSymbolName: "timer",
            variableValue: clamped,
            accessibilityDescription: "Almas Pomodoro — running"
        )?.withSymbolConfiguration(
            .init(pointSize: StatusItemStyle.pillIconPointSize, weight: .semibold)
        )
        img?.isTemplate = true
        return img
    }

    /// Static bell for the finished-flash pill — distinct silhouette
    /// from the running timer so a glance tells you which state you're in
    /// even without reading the text.
    static func finishedPill() -> NSImage? {
        let img = NSImage(
            systemSymbolName: "bell.fill",
            accessibilityDescription: "Almas Pomodoro — finished"
        )?.withSymbolConfiguration(
            .init(pointSize: StatusItemStyle.pillIconPointSize, weight: .semibold)
        )
        img?.isTemplate = true
        return img
    }

    // MARK: - Menu items (palette-coloured)

    static func play() -> NSImage? {
        palette("play.circle.fill", [NSColor.systemGreen])
    }

    static func stop() -> NSImage? {
        palette("stop.circle.fill", [NSColor.systemRed])
    }

    static func add() -> NSImage? {
        palette("plus.circle.fill", [NSColor.systemBlue])
    }

    static func remove() -> NSImage? {
        palette("trash.circle.fill", [NSColor.systemRed])
    }

    static func dismiss() -> NSImage? {
        palette("checkmark.circle.fill", [NSColor.systemGreen])
    }

    static func quit() -> NSImage? {
        palette("power.circle.fill", [NSColor.secondaryLabelColor])
    }

    static func launchAtLogin() -> NSImage? {
        palette("sunrise.circle.fill", [NSColor.systemOrange])
    }

    static func tomato() -> NSImage? {
        palette("leaf.circle.fill", [NSColor.systemRed])
    }

    static func intent() -> NSImage? {
        palette("bubble.left.fill", [NSColor.systemPurple])
    }

    // MARK: - Dialogs (larger)

    static func dialogIntent() -> NSImage? {
        NSImage(
            systemSymbolName: "sparkles",
            accessibilityDescription: nil
        )?.withSymbolConfiguration(
            .init(pointSize: 28, weight: .regular).applying(
                .init(paletteColors: [NSColor.systemPurple])
            )
        )
    }

    static func dialogAddPreset() -> NSImage? {
        NSImage(
            systemSymbolName: "plus.circle",
            accessibilityDescription: nil
        )?.withSymbolConfiguration(
            .init(pointSize: 28, weight: .regular).applying(
                .init(paletteColors: [NSColor.systemBlue])
            )
        )
    }

    // MARK: - internals

    private static func palette(
        _ name: String,
        _ colors: [NSColor],
        pointSize: CGFloat = 14,
        weight: NSFont.Weight = .semibold
    ) -> NSImage? {
        let base = NSImage(systemSymbolName: name, accessibilityDescription: nil)
        let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
            .applying(.init(paletteColors: colors))
        let img = base?.withSymbolConfiguration(config)
        img?.isTemplate = false
        return img
    }
}
