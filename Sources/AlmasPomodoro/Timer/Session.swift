import Foundation

/// A single in-flight Pomodoro session: the preset being run, the user's
/// optional stated intent for it ("I'll write 10 emails"), and the time it
/// started.
///
/// Modelled as an accretion-friendly struct rather than adding associated
/// values to `TimerState` cases directly, so future additions (e.g. tags,
/// parent-session linkage, focus-mode toggles) don't change enum arities.
struct Session: Equatable {
    let preset: Preset
    /// `nil` means the user explicitly skipped setting an intent.
    /// Non-nil is always a non-empty, trimmed string under `maxIntentLength`.
    let intent: String?
    let startedAt: Date

    static let maxIntentLength = 280

    init(preset: Preset, intent: String?, startedAt: Date = Date()) throws {
        self.preset = preset
        self.startedAt = startedAt
        self.intent = try Session.normalize(intent: intent)
    }

    /// Whitespace-only or nil input both collapse to `nil` (= skipped).
    /// Strings exceeding the sanity ceiling throw.
    static func normalize(intent raw: String?) throws -> String? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard trimmed.count <= Session.maxIntentLength else {
            throw SessionError.intentTooLong(trimmed.count)
        }
        return trimmed
    }
}

enum SessionError: Error, Equatable, CustomStringConvertible {
    case intentTooLong(Int)

    var description: String {
        switch self {
        case .intentTooLong(let n):
            return "Intent is \(n) characters; max is \(Session.maxIntentLength)."
        }
    }
}
