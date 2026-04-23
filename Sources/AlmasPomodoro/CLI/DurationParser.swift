import Foundation

/// Parses human-written durations (`"25"`, `"25m"`, `"25min"`, `"1h30m"`,
/// `"90s"`, …) into a positive number of seconds.
///
/// Grammar (case-insensitive, whitespace trimmed):
///
///     duration   := token+ | bare_int
///     bare_int   := <digits>                 # interpreted as minutes
///     token      := <digits> unit
///     unit       := h | hr | hrs | hour | hours
///                  | m | min | mins | minute | minutes
///                  | s | sec | secs | second | seconds
///
/// Tokens in a compound duration may appear in any order; they are summed.
/// Zero or negative totals and > 24h totals are rejected — those are always
/// mistakes in this domain, not silent-fallback situations.
enum DurationParser {

    enum ParseError: Error, Equatable, CustomStringConvertible {
        case empty
        case invalid(String)
        case nonPositive
        case overflow(Int)

        var description: String {
            switch self {
            case .empty:
                return "Duration is empty."
            case .invalid(let raw):
                return "Cannot parse duration \(String(reflecting: raw))."
            case .nonPositive:
                return "Duration must be greater than zero."
            case .overflow(let s):
                return "Duration \(s)s exceeds the 24h ceiling."
            }
        }
    }

    static func parseSeconds(_ input: String) throws -> Int {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { throw ParseError.empty }

        // Bare integer = minutes (what you mean when you type `almaspom 25`).
        if trimmed.allSatisfy(\.isNumber), let minutes = Int(trimmed) {
            return try finalize(seconds: minutes * 60, raw: input)
        }

        var cursor = Substring(trimmed)
        var total = 0
        var matchedAny = false
        while !cursor.isEmpty {
            guard let scan = scanToken(cursor) else {
                throw ParseError.invalid(input)
            }
            total += scan.value * scan.unit.multiplier
            cursor = scan.rest
            matchedAny = true
        }
        guard matchedAny else { throw ParseError.invalid(input) }
        return try finalize(seconds: total, raw: input)
    }

    // MARK: - Internals

    private enum Unit {
        case hours, minutes, seconds
        var multiplier: Int {
            switch self {
            case .hours: return 3600
            case .minutes: return 60
            case .seconds: return 1
            }
        }
    }

    /// Longest-suffix-first so `min` wins over `m`, `hours` over `hr`/`h`, etc.
    private static let unitSuffixes: [(String, Unit)] = [
        ("hours", .hours), ("hour", .hours), ("hrs", .hours), ("hr", .hours), ("h", .hours),
        ("minutes", .minutes), ("minute", .minutes), ("mins", .minutes), ("min", .minutes), ("m", .minutes),
        ("seconds", .seconds), ("second", .seconds), ("secs", .seconds), ("sec", .seconds), ("s", .seconds)
    ]

    private static func scanToken(_ s: Substring) -> (value: Int, unit: Unit, rest: Substring)? {
        var i = s.startIndex
        while i < s.endIndex, s[i].isNumber {
            i = s.index(after: i)
        }
        guard i > s.startIndex, let value = Int(s[s.startIndex..<i]) else { return nil }
        let tail = s[i...]
        for (suffix, unit) in unitSuffixes where tail.hasPrefix(suffix) {
            let after = tail.dropFirst(suffix.count)
            return (value, unit, after)
        }
        return nil
    }

    private static func finalize(seconds: Int, raw: String) throws -> Int {
        guard seconds > 0 else { throw ParseError.nonPositive }
        guard seconds <= Preset.maxSeconds else { throw ParseError.overflow(seconds) }
        return seconds
    }
}
