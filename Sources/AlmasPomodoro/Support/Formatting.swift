import Foundation

enum Formatting {
    /// Renders a non-negative integer count of seconds as `MM:SS`.
    /// Fails fast on negative input — callers must not pass negatives.
    static func clock(_ seconds: Int) -> String {
        precondition(seconds >= 0, "Formatting.clock requires non-negative seconds, got \(seconds)")
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    /// Renders a duration as a short, human label: "25m", "90m", "45s".
    static func shortDuration(_ seconds: Int) -> String {
        precondition(seconds > 0, "shortDuration requires positive seconds, got \(seconds)")
        if seconds % 60 == 0 { return "\(seconds / 60)m" }
        if seconds < 60 { return "\(seconds)s" }
        let m = seconds / 60
        let s = seconds % 60
        return "\(m)m\(s)s"
    }
}
