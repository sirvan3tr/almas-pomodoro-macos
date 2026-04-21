import AppKit

/// Visual tokens for the menu-bar item. Kept as data (a plain enum + values)
/// so the rendering code is a pure function of state.
enum StatusItemStyle {
    /// Pomodoro-classic purple. High-contrast white text lives on top of it.
    static let runningBackground = NSColor(
        calibratedRed: 0.42, green: 0.27, blue: 0.76, alpha: 1.0
    )
    static let runningForeground = NSColor.white

    /// Finish flash colour A (warm orange). Chosen to be visually distinct
    /// from the running purple so a glance identifies "done, not running".
    static let flashOnBackground = NSColor(
        calibratedRed: 0.98, green: 0.55, blue: 0.15, alpha: 1.0
    )
    /// Finish flash colour B (deep red). Alternates with A while flashing.
    static let flashOffBackground = NSColor(
        calibratedRed: 0.85, green: 0.15, blue: 0.20, alpha: 1.0
    )
    static let flashForeground = NSColor.white

    /// Idle state uses the standard system tint — no filled background so
    /// the menu bar looks like any other well-behaved status item.
    static let idleForeground = NSColor.labelColor

    /// Corner radius of the filled pill shown during running/finished.
    static let cornerRadius: CGFloat = 4.0

    /// Interval between flash toggles when finished.
    static let flashInterval: TimeInterval = 0.5
}
