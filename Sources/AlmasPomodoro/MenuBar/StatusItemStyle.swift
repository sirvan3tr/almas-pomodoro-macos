import AppKit

/// Visual tokens for the menu-bar item. Kept as data (plain constants) so the
/// rendering code stays a pure function of state + these tokens.
enum StatusItemStyle {

    // MARK: - Colours

    /// Pomodoro-classic purple. High-contrast white text lives on top of it.
    static let runningBackground = NSColor(
        calibratedRed: 0.42, green: 0.27, blue: 0.76, alpha: 1.0
    )
    static let runningForeground = NSColor.white

    /// Finish flash colour A (warm amber). Chosen to be visually distinct
    /// from the running purple so a glance identifies "done, not running".
    static let flashOnBackground = NSColor(
        calibratedRed: 0.98, green: 0.55, blue: 0.15, alpha: 1.0
    )
    /// Finish flash colour B (deep red). Crossfades with A while flashing.
    static let flashOffBackground = NSColor(
        calibratedRed: 0.85, green: 0.15, blue: 0.20, alpha: 1.0
    )
    static let flashForeground = NSColor.white

    // MARK: - Geometry & type

    /// Corner radius of the filled pill shown during running/finished.
    static let cornerRadius: CGFloat = 6.0

    /// Font used for the running countdown / finished label.
    static let pillFont = NSFont.monospacedDigitSystemFont(ofSize: 12.5, weight: .semibold)

    // MARK: - Animation

    /// Interval between flash colour toggles while finished.
    static let flashInterval: TimeInterval = 0.6
    /// Duration of the colour crossfade between toggles (smoother than a hard
    /// switch; total cycle still equals `flashInterval`).
    static let flashCrossfade: TimeInterval = 0.35
}
