import Foundation

/// Persists user presets to `~/Library/Application Support/AlmasPomodoro/presets.json`.
///
/// Design:
///   - Accretion-friendly on-disk schema: a top-level object with a `presets`
///     array. Unknown keys are preserved on read and re-emitted on write
///     (open-world semantics).
///   - Corrupt files are NOT silently discarded. They are renamed with a
///     `.corrupt-<unix-ts>` suffix and the failure is surfaced to the caller.
///   - Writes are atomic.
final class PresetStore {
    private let fileURL: URL
    private let fileManager: FileManager

    /// Decoded payload retained so that unknown/forward-compatible keys
    /// survive a round-trip. The concrete `presets` array is the
    /// authoritative list for the rest of the app.
    private(set) var presets: [Preset]
    private var unknown: [String: AnyCodable]

    init(fileURL: URL? = nil, fileManager: FileManager = .default) throws {
        self.fileManager = fileManager
        self.fileURL = try fileURL ?? PresetStore.defaultFileURL(fileManager: fileManager)
        let loaded = try PresetStore.loadFrom(url: self.fileURL, fileManager: fileManager)
        self.presets = loaded.presets
        self.unknown = loaded.unknown
    }

    static func defaultFileURL(fileManager: FileManager = .default) throws -> URL {
        let appSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dir = appSupport.appendingPathComponent("AlmasPomodoro", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("presets.json", isDirectory: false)
    }

    /// Append a new preset. Never mutates existing ones (accretion).
    func append(_ preset: Preset) throws {
        presets.append(preset)
        try save()
    }

    /// Remove a preset by id. Returns true if removed.
    @discardableResult
    func remove(id: UUID) throws -> Bool {
        let before = presets.count
        presets.removeAll { $0.id == id }
        guard presets.count != before else { return false }
        try save()
        return true
    }

    // MARK: - I/O

    private struct Payload: Codable {
        var presets: [Preset]
        // Catch-all for forward-compat keys. Encoded/decoded via AnyCodable.
    }

    private static func loadFrom(url: URL, fileManager: FileManager) throws -> (presets: [Preset], unknown: [String: AnyCodable]) {
        guard fileManager.fileExists(atPath: url.path) else {
            let seeded = Preset.defaults
            let store = TempEmitter(url: url)
            try store.emit(presets: seeded, unknown: [:])
            return (seeded, [:])
        }
        let data = try Data(contentsOf: url)
        do {
            let dict = try JSONDecoder().decode([String: AnyCodable].self, from: data)
            guard let rawPresets = dict["presets"]?.value as? [Any] else {
                throw StoreError.missingPresetsKey
            }
            let decodedPresets: [Preset] = try rawPresets.enumerated().map { (idx, raw) in
                guard let obj = raw as? [String: Any] else { throw StoreError.malformedEntry(idx) }
                let entryData = try JSONSerialization.data(withJSONObject: obj)
                return try JSONDecoder().decode(Preset.self, from: entryData)
            }
            var unknown = dict
            unknown.removeValue(forKey: "presets")
            return (decodedPresets, unknown)
        } catch {
            try Self.quarantine(url: url, fileManager: fileManager)
            throw StoreError.corrupt(underlying: error)
        }
    }

    private func save() throws {
        var dict: [String: AnyCodable] = unknown
        let presetsJSON = try presets.map { preset -> Any in
            let data = try JSONEncoder().encode(preset)
            return try JSONSerialization.jsonObject(with: data)
        }
        dict["presets"] = AnyCodable(presetsJSON)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let out = try encoder.encode(dict)
        try out.write(to: fileURL, options: [.atomic])
    }

    private static func quarantine(url: URL, fileManager: FileManager) throws {
        let ts = Int(Date().timeIntervalSince1970)
        let bad = url.deletingPathExtension()
            .appendingPathExtension("corrupt-\(ts).json")
        try? fileManager.removeItem(at: bad)
        try fileManager.moveItem(at: url, to: bad)
    }

    enum StoreError: Error, CustomStringConvertible {
        case missingPresetsKey
        case malformedEntry(Int)
        case corrupt(underlying: Error)

        var description: String {
            switch self {
            case .missingPresetsKey: return "presets.json is missing required `presets` key."
            case .malformedEntry(let i): return "presets.json entry at index \(i) is not an object."
            case .corrupt(let e): return "presets.json is corrupt: \(e). The file has been quarantined."
            }
        }
    }
}

/// Tiny writer used at first-run when we need to seed defaults before the
/// owning `PresetStore` has finished initialising (avoids a chicken-and-egg
/// problem with the instance-level `unknown` dict).
private struct TempEmitter {
    let url: URL
    func emit(presets: [Preset], unknown: [String: AnyCodable]) throws {
        var dict: [String: AnyCodable] = unknown
        let arr = try presets.map { preset -> Any in
            let data = try JSONEncoder().encode(preset)
            return try JSONSerialization.jsonObject(with: data)
        }
        dict["presets"] = AnyCodable(arr)
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        let out = try enc.encode(dict)
        try out.write(to: url, options: [.atomic])
    }
}
