import AppKit
import CoreFoundation

/// CFMessagePort client that sends a `Command` and returns a `Response`.
///
/// If the well-known port isn't registered (GUI not running), the client
/// launches the menu-bar app via Launch Services and retries for up to
/// a short budget. Any persistent failure is surfaced to the caller —
/// we never swallow an IPC error silently.
enum CLIClient {

    enum ClientError: Error, CustomStringConvertible {
        case guiUnreachable
        case sendFailed(Int32)
        case decodeFailed(Error)
        case encodeFailed(Error)

        var description: String {
            switch self {
            case .guiUnreachable:
                return "Could not reach the Almas Pomodoro app. Is it installed?"
            case .sendFailed(let code):
                return "IPC send failed (CFMessagePort status \(code))."
            case .decodeFailed(let e):
                return "Could not decode response: \(e)"
            case .encodeFailed(let e):
                return "Could not encode command: \(e)"
            }
        }
    }

    static func send(
        _ command: Command,
        autoLaunch: Bool = true
    ) throws -> Response {
        let payload: Data
        do {
            payload = try JSONEncoder().encode(command)
        } catch {
            throw ClientError.encodeFailed(error)
        }

        let port = try acquirePort(autoLaunch: autoLaunch)

        var rawReply: Unmanaged<CFData>?
        let status = CFMessagePortSendRequest(
            port,
            0,                              // msgid (unused)
            payload as CFData,
            IPC.timeout,
            IPC.timeout,
            CFRunLoopMode.defaultMode.rawValue,
            &rawReply
        )
        guard status == Int32(kCFMessagePortSuccess) else {
            throw ClientError.sendFailed(status)
        }
        let replyData = (rawReply?.takeRetainedValue() as Data?) ?? Data()
        do {
            return try JSONDecoder().decode(Response.self, from: replyData)
        } catch {
            throw ClientError.decodeFailed(error)
        }
    }

    // MARK: - Port discovery

    private static func acquirePort(autoLaunch: Bool) throws -> CFMessagePort {
        if let p = CFMessagePortCreateRemote(nil, IPC.portName as CFString) {
            return p
        }
        guard autoLaunch else { throw ClientError.guiUnreachable }

        launchGUI()

        // Poll for the port to appear. ~3 seconds is plenty on a warm
        // machine; if it takes longer the GUI is in trouble and we
        // surface the failure rather than hanging forever.
        let deadline = Date().addingTimeInterval(3.0)
        while Date() < deadline {
            if let p = CFMessagePortCreateRemote(nil, IPC.portName as CFString) {
                return p
            }
            Thread.sleep(forTimeInterval: 0.1)
        }
        throw ClientError.guiUnreachable
    }

    /// Launch the bundled .app. We prefer Launch Services (`open -b`) so
    /// the binary's menu-bar registration is handled by the OS rather than
    /// forking a child tied to the terminal session.
    private static func launchGUI() {
        let candidates: [() -> URL?] = [
            {
                NSWorkspace.shared.urlForApplication(
                    withBundleIdentifier: "sh.almas.pomodoro"
                )
            },
            {
                let home = FileManager.default.homeDirectoryForCurrentUser
                return home.appendingPathComponent("Applications/AlmasPomodoro.app")
            },
            { URL(fileURLWithPath: "/Applications/AlmasPomodoro.app") }
        ]
        for resolve in candidates {
            guard let url = resolve(), FileManager.default.fileExists(atPath: url.path) else {
                continue
            }
            let cfg = NSWorkspace.OpenConfiguration()
            cfg.activates = false
            cfg.addsToRecentItems = false
            let sema = DispatchSemaphore(value: 0)
            NSWorkspace.shared.openApplication(at: url, configuration: cfg) { _, _ in
                sema.signal()
            }
            _ = sema.wait(timeout: .now() + 2.0)
            return
        }
    }
}
