import Foundation

/// A named, positive-duration timer preset.
///
/// Invariants (enforced at construction — fail fast):
///   - `name` is non-empty after whitespace trim
///   - `seconds` is strictly positive
///   - `seconds` <= 24h (sanity ceiling; we are not a scheduler)
struct Preset: Codable, Equatable, Identifiable {
    let id: UUID
    let name: String
    let seconds: Int

    static let maxSeconds = 24 * 60 * 60

    init(id: UUID = UUID(), name: String, seconds: Int) throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw PresetError.emptyName }
        guard seconds > 0 else { throw PresetError.nonPositiveDuration(seconds) }
        guard seconds <= Preset.maxSeconds else { throw PresetError.tooLong(seconds) }
        self.id = id
        self.name = trimmed
        self.seconds = seconds
    }
}

enum PresetError: Error, Equatable, CustomStringConvertible {
    case emptyName
    case nonPositiveDuration(Int)
    case tooLong(Int)
    case invalidMinutes(String)

    var description: String {
        switch self {
        case .emptyName:
            return "Preset name cannot be empty."
        case .nonPositiveDuration(let s):
            return "Duration must be positive, got \(s) seconds."
        case .tooLong(let s):
            return "Duration exceeds 24h ceiling (\(s) seconds)."
        case .invalidMinutes(let raw):
            return "Could not parse minutes from \(String(reflecting: raw))."
        }
    }
}

extension Preset {
    /// Classic Pomodoro defaults. Deliberately constrained, not configurable
    /// from outside — callers wanting different defaults should persist their
    /// own presets via `PresetStore`.
    static let defaults: [Preset] = {
        // force-try because these literals are known-valid and any failure here
        // is a programmer error we want surfaced immediately on launch.
        [
            try! Preset(name: "Pomodoro", seconds: 25 * 60),
            try! Preset(name: "Short Break", seconds: 5 * 60),
            try! Preset(name: "Long Break", seconds: 15 * 60)
        ]
    }()
}
