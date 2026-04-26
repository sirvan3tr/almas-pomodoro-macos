import Foundation
import ServiceManagement

/// Thin wrapper around `SMAppService.mainApp` for the "launch at login"
/// toggle.
///
/// The OS persists state for us — we just expose a small, total surface
/// (`isEnabled`, `setEnabled`) so the menu doesn't have to know anything
/// about ServiceManagement.
///
/// Failure modes are surfaced (not swallowed): if the OS rejects a
/// register/unregister, the caller hears about it.
enum LaunchAtLogin {

    enum Error: Swift.Error, CustomStringConvertible {
        case registerFailed(Swift.Error)
        case unregisterFailed(Swift.Error)
        case requiresAppBundle

        var description: String {
            switch self {
            case .registerFailed(let e):
                return "Could not enable launch at login: \(e)"
            case .unregisterFailed(let e):
                return "Could not disable launch at login: \(e)"
            case .requiresAppBundle:
                return """
                "Launch at login" only works when running from an installed \
                .app bundle. Run `make install` first.
                """
            }
        }
    }

    /// Whether the "launch at login" toggle is currently armed.
    /// Returns `false` if the underlying status is not exactly `.enabled`
    /// — partial states (`requiresApproval`, `notRegistered`, `notFound`)
    /// all read as off, which matches what a user expects from a toggle.
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Whether the toggle is operable in this run. SMAppService refuses
    /// to register a binary that isn't running from a real .app bundle.
    static var isAvailable: Bool {
        // Loose heuristic: a real bundled launch has Bundle.main pointing
        // inside something ending in ".app". Hardened against the SwiftPM
        // `swift run` path (which uses the .build/debug binary directly).
        Bundle.main.bundlePath.hasSuffix(".app")
    }

    static func setEnabled(_ enabled: Bool) throws {
        guard isAvailable else { throw Error.requiresAppBundle }
        let service = SMAppService.mainApp
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
        } catch let underlying {
            throw enabled
                ? Error.registerFailed(underlying)
                : Error.unregisterFailed(underlying)
        }
    }
}
