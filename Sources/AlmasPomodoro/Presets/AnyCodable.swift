import Foundation

/// Minimal type-erased Codable wrapper.
///
/// Used by `PresetStore` to round-trip unknown top-level keys so forward-
/// compatible additions to the on-disk format are preserved (open-world
/// semantics).
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) { self.value = value }

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self.value = NSNull(); return }
        if let b = try? c.decode(Bool.self) { self.value = b; return }
        if let i = try? c.decode(Int.self) { self.value = i; return }
        if let d = try? c.decode(Double.self) { self.value = d; return }
        if let s = try? c.decode(String.self) { self.value = s; return }
        if let a = try? c.decode([AnyCodable].self) { self.value = a.map { $0.value }; return }
        if let m = try? c.decode([String: AnyCodable].self) {
            self.value = m.mapValues { $0.value }; return
        }
        throw DecodingError.dataCorruptedError(
            in: c,
            debugDescription: "AnyCodable: unsupported JSON value"
        )
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch value {
        case is NSNull:
            try c.encodeNil()
        case let b as Bool:
            try c.encode(b)
        case let i as Int:
            try c.encode(i)
        case let d as Double:
            try c.encode(d)
        case let s as String:
            try c.encode(s)
        case let a as [Any]:
            try c.encode(a.map(AnyCodable.init))
        case let m as [String: Any]:
            try c.encode(m.mapValues(AnyCodable.init))
        default:
            let data = try JSONSerialization.data(withJSONObject: value, options: [.fragmentsAllowed])
            let fallback = try JSONDecoder().decode(AnyCodable.self, from: data)
            try c.encode(fallback)
        }
    }
}
