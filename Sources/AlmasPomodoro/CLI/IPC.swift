import Foundation

/// Wire format shared between the `almaspom` CLI and the running
/// menu-bar GUI. Both sides speak JSON; these types are the contract.
///
/// Design principles (per AGENTS.md):
///   * Prioritise the machine interface — the GUI and CLI both act as
///     clients of the same command bus.
///   * Open-world semantics — unknown fields are ignored on decode so
///     newer clients can talk to older servers without breakage.
///   * Accretion, not breakage — add new commands by introducing new
///     cases; never repurpose the meaning of an existing case.
enum IPC {
    /// Well-known CFMessagePort name. Keeping it here so every reference
    /// is exactly one string literal away from the truth.
    static let portName = "sh.almas.pomodoro.control"

    /// Request/response timeout for CLI round-trips (seconds).
    static let timeout: CFTimeInterval = 2.0
}

// MARK: - Command

enum Command: Equatable {
    case ping
    case status
    case start(seconds: Int, name: String?, intent: String?)
    case startPreset(name: String, intent: String?)
    case stop
    case acknowledge
    case presetsList
    case presetsAdd(name: String, seconds: Int)
    case presetsRemove(name: String)
}

extension Command: Codable {
    private enum Kind: String, Codable {
        case ping
        case status
        case start
        case startPreset = "start.preset"
        case stop
        case acknowledge
        case presetsList = "presets.list"
        case presetsAdd  = "presets.add"
        case presetsRemove = "presets.remove"
    }

    private enum CodingKeys: String, CodingKey {
        case type, seconds, name, intent
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .ping:
            try c.encode(Kind.ping, forKey: .type)
        case .status:
            try c.encode(Kind.status, forKey: .type)
        case .start(let seconds, let name, let intent):
            try c.encode(Kind.start, forKey: .type)
            try c.encode(seconds, forKey: .seconds)
            try c.encodeIfPresent(name, forKey: .name)
            try c.encodeIfPresent(intent, forKey: .intent)
        case .startPreset(let name, let intent):
            try c.encode(Kind.startPreset, forKey: .type)
            try c.encode(name, forKey: .name)
            try c.encodeIfPresent(intent, forKey: .intent)
        case .stop:
            try c.encode(Kind.stop, forKey: .type)
        case .acknowledge:
            try c.encode(Kind.acknowledge, forKey: .type)
        case .presetsList:
            try c.encode(Kind.presetsList, forKey: .type)
        case .presetsAdd(let name, let seconds):
            try c.encode(Kind.presetsAdd, forKey: .type)
            try c.encode(name, forKey: .name)
            try c.encode(seconds, forKey: .seconds)
        case .presetsRemove(let name):
            try c.encode(Kind.presetsRemove, forKey: .type)
            try c.encode(name, forKey: .name)
        }
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try c.decode(Kind.self, forKey: .type)
        switch kind {
        case .ping:  self = .ping
        case .status: self = .status
        case .stop:  self = .stop
        case .acknowledge: self = .acknowledge
        case .presetsList: self = .presetsList
        case .start:
            let seconds = try c.decode(Int.self, forKey: .seconds)
            let name = try c.decodeIfPresent(String.self, forKey: .name)
            let intent = try c.decodeIfPresent(String.self, forKey: .intent)
            self = .start(seconds: seconds, name: name, intent: intent)
        case .startPreset:
            let name = try c.decode(String.self, forKey: .name)
            let intent = try c.decodeIfPresent(String.self, forKey: .intent)
            self = .startPreset(name: name, intent: intent)
        case .presetsAdd:
            let name = try c.decode(String.self, forKey: .name)
            let seconds = try c.decode(Int.self, forKey: .seconds)
            self = .presetsAdd(name: name, seconds: seconds)
        case .presetsRemove:
            let name = try c.decode(String.self, forKey: .name)
            self = .presetsRemove(name: name)
        }
    }
}

// MARK: - Status (value object carried in responses)

struct StatusSnapshot: Codable, Equatable {
    enum State: String, Codable {
        case idle, running, finished
    }

    let state: State
    /// Preset display name, or nil when idle.
    let preset: String?
    /// Total configured duration of the current session (seconds).
    let totalSeconds: Int?
    /// Remaining seconds in the current session (only populated when running).
    let remainingSeconds: Int?
    /// Intent the user set at session start, if any.
    let intent: String?

    static let idle = StatusSnapshot(
        state: .idle,
        preset: nil,
        totalSeconds: nil,
        remainingSeconds: nil,
        intent: nil
    )
}

// MARK: - Response

enum Response: Equatable {
    case ok(StatusSnapshot)
    case presets(list: [PresetInfo])
    case error(message: String)
}

struct PresetInfo: Codable, Equatable {
    let name: String
    let seconds: Int
}

extension Response: Codable {
    private enum Kind: String, Codable {
        case ok, presets, error
    }

    private enum CodingKeys: String, CodingKey {
        case type, status, presets, message
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .ok(let snapshot):
            try c.encode(Kind.ok, forKey: .type)
            try c.encode(snapshot, forKey: .status)
        case .presets(let list):
            try c.encode(Kind.presets, forKey: .type)
            try c.encode(list, forKey: .presets)
        case .error(let message):
            try c.encode(Kind.error, forKey: .type)
            try c.encode(message, forKey: .message)
        }
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try c.decode(Kind.self, forKey: .type)
        switch kind {
        case .ok:
            self = .ok(try c.decode(StatusSnapshot.self, forKey: .status))
        case .presets:
            self = .presets(list: try c.decode([PresetInfo].self, forKey: .presets))
        case .error:
            self = .error(message: try c.decode(String.self, forKey: .message))
        }
    }
}
