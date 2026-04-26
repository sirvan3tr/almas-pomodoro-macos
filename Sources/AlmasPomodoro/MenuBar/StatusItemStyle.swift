import AppKit

/// Visual tokens for the menu-bar item.
///
/// Colour decisions:
///
///   * `systemPurple` for running. System colours adapt to light/dark
///     appearance automatically and stay readable when the menu bar
///     itself is translucent over a coloured wallpaper.
///   * The finish flash pairs **amber** with **indigo** rather than the
///     classic red/orange. Red/green-deficient users (the most common
///     form of colour blindness, ~8% of men) cannot reliably tell red
///     from orange; amber↔indigo keeps strong luminance *and* hue
///     contrast across protan, deutan, and tritan deficiencies.
///   * Foreground stays white on every coloured pill — the system
///     colours are tuned to keep WCAG AA contrast against white.
///
/// Tokens, not behaviour: rendering code reads from here and never
/// hard-codes colour values.
enum StatusItemStyle {

    // MARK: - Colours

    static let runningBackground = NSColor.systemPurple
    static let runningForeground = NSColor.white

    /// Amber — warm, "warm-up to the bell" cue. Good contrast in both
    /// light and dark menu bars.
    static let flashOnBackground  = NSColor.systemOrange
    /// Indigo — distinct from amber across all common colour-blindness
    /// types and across light/dark appearance.
    static let flashOffBackground = NSColor.systemIndigo
    static let flashForeground    = NSColor.white

    // MARK: - Geometry & type

    static let cornerRadius: CGFloat = 6.0
    static let pillFont = NSFont.monospacedDigitSystemFont(ofSize: 12.5, weight: .semibold)
    static let pillIconPointSize: CGFloat = 12.0

    // MARK: - Animation

    /// Interval between flash colour toggles while finished.
    static let flashInterval: TimeInterval = 0.6
    /// Cross-fade duration between flash colours; smooths the toggle so
    /// it reads as a "breathing" alarm rather than a strobe.
    static let flashCrossfade: TimeInterval = 0.35
}
