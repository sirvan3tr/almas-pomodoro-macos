import AppKit

/// Modal prompt shown when the user chooses to start a preset.
///
/// Three outcomes, encoded as an enum so callers can't misinterpret them:
///   - `.confirmed(intent: String)`  — start with the typed intent
///   - `.skipped`                    — start, but no intent recorded
///   - `.cancelled`                  — don't start at all (Esc or Cancel)
///
/// The dialog revalidates via `Session.normalize` so whatever leaves this
/// function is already a legal intent value.
@MainActor
enum IntentDialog {

    enum Outcome: Equatable {
        case confirmed(intent: String)
        case skipped
        case cancelled
    }

    static func present(for preset: Preset) -> Outcome {
        while true {
            let raw = runOnce(
                preset: preset,
                errorText: nil,
                prefill: ""
            )
            switch raw {
            case .cancel:
                return .cancelled
            case .skip:
                return .skipped
            case .start(let text):
                do {
                    if let normalized = try Session.normalize(intent: text) {
                        return .confirmed(intent: normalized)
                    } else {
                        // Start pressed with empty text == skip (be forgiving).
                        return .skipped
                    }
                } catch {
                    // Re-present with the bad value preserved and an error hint.
                    let retry = runOnce(
                        preset: preset,
                        errorText: String(describing: error),
                        prefill: text
                    )
                    switch retry {
                    case .cancel: return .cancelled
                    case .skip:   return .skipped
                    case .start:  continue   // loop again with fresh prefill state
                    }
                }
            }
        }
    }

    // MARK: - Internals

    private enum RawOutcome {
        case start(String)
        case skip
        case cancel
    }

    private static func runOnce(
        preset: Preset,
        errorText: String?,
        prefill: String
    ) -> RawOutcome {
        let alert = NSAlert()
        alert.messageText = "Start \(preset.name) — \(Formatting.shortDuration(preset.seconds))"
        alert.informativeText = errorText
            ?? "What will you do this session? (e.g. “Write 10 emails.”) You can skip."
        alert.alertStyle = errorText == nil ? .informational : .warning

        // Order matters: first button is the default (Enter),
        // and NSAlert auto-maps a button titled "Cancel" to Esc.
        alert.addButton(withTitle: "Start")
        alert.addButton(withTitle: "Skip")
        alert.addButton(withTitle: "Cancel")

        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        field.placeholderString = "Session intent (optional)"
        field.stringValue = prefill
        alert.accessoryView = field
        alert.window.initialFirstResponder = field

        switch alert.runModal() {
        case .alertFirstButtonReturn:  return .start(field.stringValue)
        case .alertSecondButtonReturn: return .skip
        default:                       return .cancel
        }
    }
}
