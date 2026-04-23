import AppKit
import CoreFoundation

/// In-process command bus that accepts JSON-encoded `Command`s over
/// `CFMessagePort` and dispatches them against the live `PomodoroTimer`
/// and `PresetStore`.
///
/// Why CFMessagePort: it's the lowest-friction, entitlement-free,
/// per-user IPC primitive on macOS. The name is a well-known constant
/// in `IPC.portName`, so the CLI can find us deterministically.
///
/// This type is the *single* place where incoming commands touch app
/// state — keeping the surface auditable and trivially testable via
/// `handle(requestData:)`.
@MainActor
final class CommandServer {

    private let timer: PomodoroTimer
    private let presetStore: PresetStore
    private var port: CFMessagePort?

    init(timer: PomodoroTimer, presetStore: PresetStore) {
        self.timer = timer
        self.presetStore = presetStore
    }

    func start() {
        guard port == nil else { return }

        var context = CFMessagePortContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        // Callback is @convention(c); no Swift captures allowed, so we
        // route back to `self` via the context info pointer.
        let callback: CFMessagePortCallBack = { (_, _, data, info) in
            guard let info else { return nil }
            let server = Unmanaged<CommandServer>.fromOpaque(info).takeUnretainedValue()
            let request = (data as Data?) ?? Data()
            let reply = MainActor.assumeIsolated { server.handle(requestData: request) }
            return Unmanaged.passRetained(reply as CFData)
        }

        guard let newPort = CFMessagePortCreateLocal(
            nil,
            IPC.portName as CFString,
            callback,
            &context,
            nil
        ) else {
            NSLog("[AlmasPomodoro] Could not create CFMessagePort at \(IPC.portName).")
            return
        }
        self.port = newPort

        let source = CFMessagePortCreateRunLoopSource(nil, newPort, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
    }

    // MARK: - Request handling (exposed for tests)

    func handle(requestData: Data) -> Data {
        let response: Response
        do {
            let command = try JSONDecoder().decode(Command.self, from: requestData)
            response = execute(command)
        } catch {
            response = .error(message: "Malformed request: \(error)")
        }
        return (try? JSONEncoder().encode(response))
            ?? Data(#"{"type":"error","message":"encode failure"}"#.utf8)
    }

    private func execute(_ command: Command) -> Response {
        switch command {
        case .ping:
            return .ok(snapshot())
        case .status:
            return .ok(snapshot())
        case .stop:
            timer.stop()
            return .ok(snapshot())
        case .acknowledge:
            timer.acknowledge()
            return .ok(snapshot())
        case .start(let seconds, let name, let intent):
            return startAdHoc(seconds: seconds, name: name, intent: intent)
        case .startPreset(let name, let intent):
            return startNamedPreset(name: name, intent: intent)
        case .presetsList:
            let list = presetStore.presets.map {
                PresetInfo(name: $0.name, seconds: $0.seconds)
            }
            return .presets(list: list)
        case .presetsAdd(let name, let seconds):
            do {
                let preset = try Preset(name: name, seconds: seconds)
                try presetStore.append(preset)
                return .ok(snapshot())
            } catch {
                return .error(message: String(describing: error))
            }
        case .presetsRemove(let name):
            let matches = presetStore.presets.filter { $0.name.caseInsensitiveCompare(name) == .orderedSame }
            guard let target = matches.first else {
                return .error(message: "No preset named \(String(reflecting: name)).")
            }
            do {
                try presetStore.remove(id: target.id)
                return .ok(snapshot())
            } catch {
                return .error(message: String(describing: error))
            }
        }
    }

    // MARK: - Start helpers

    private func startAdHoc(seconds: Int, name: String?, intent: String?) -> Response {
        do {
            let displayName = (name?.trimmingCharacters(in: .whitespacesAndNewlines))
                .flatMap { $0.isEmpty ? nil : $0 }
                ?? "Timer"
            let preset = try Preset(name: displayName, seconds: seconds)
            let session = try Session(preset: preset, intent: intent)
            timer.start(session)
            return .ok(snapshot())
        } catch {
            return .error(message: String(describing: error))
        }
    }

    private func startNamedPreset(name: String, intent: String?) -> Response {
        let matches = presetStore.presets.filter {
            $0.name.caseInsensitiveCompare(name) == .orderedSame
        }
        guard let preset = matches.first else {
            return .error(message: "No preset named \(String(reflecting: name)).")
        }
        do {
            let session = try Session(preset: preset, intent: intent)
            timer.start(session)
            return .ok(snapshot())
        } catch {
            return .error(message: String(describing: error))
        }
    }

    // MARK: - Snapshot

    private func snapshot() -> StatusSnapshot {
        switch timer.state {
        case .idle:
            return .idle
        case .running(let session, let remaining):
            return StatusSnapshot(
                state: .running,
                preset: session.preset.name,
                totalSeconds: session.preset.seconds,
                remainingSeconds: remaining,
                intent: session.intent
            )
        case .finished(let session):
            return StatusSnapshot(
                state: .finished,
                preset: session.preset.name,
                totalSeconds: session.preset.seconds,
                remainingSeconds: 0,
                intent: session.intent
            )
        }
    }
}
