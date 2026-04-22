import AppKit

/// Simple modal dialog for capturing a new preset.
///
/// Returns a constructed `Preset` or throws. Input is validated at the
/// `Preset` initializer — this keeps the dialog's job purely to gather
/// text and surface errors back to the user.
@MainActor
enum AddPresetDialog {

    static func present() -> Preset? {
        while true {
            let result = runOnce(errorText: nil)
            switch result {
            case .cancelled:
                return nil
            case .submitted(let name, let minutesStr):
                do {
                    let preset = try buildPreset(name: name, minutesStr: minutesStr)
                    return preset
                } catch {
                    if case .cancelled = runOnce(
                        errorText: String(describing: error),
                        prefillName: name,
                        prefillMinutes: minutesStr
                    ) {
                        return nil
                    }
                }
            }
        }
    }

    // MARK: - Internals

    private enum Outcome {
        case cancelled
        case submitted(name: String, minutesStr: String)
    }

    private static func buildPreset(name: String, minutesStr: String) throws -> Preset {
        let raw = minutesStr.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let minutes = Int(raw) else {
            throw PresetError.invalidMinutes(minutesStr)
        }
        return try Preset(name: name, seconds: minutes * 60)
    }

    private static func runOnce(
        errorText: String?,
        prefillName: String = "",
        prefillMinutes: String = ""
    ) -> Outcome {
        let alert = NSAlert()
        alert.messageText = "Add custom timer"
        alert.informativeText = errorText ?? "Give it a short name and a duration in whole minutes."
        alert.alertStyle = errorText == nil ? .informational : .warning
        if let icon = Icons.dialogAddPreset() {
            alert.icon = icon
        }
        alert.addButton(withTitle: "Add")
        alert.addButton(withTitle: "Cancel")

        let container = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 64))

        let nameField = NSTextField(frame: NSRect(x: 0, y: 32, width: 300, height: 24))
        nameField.placeholderString = "Name (e.g. Deep Work)"
        nameField.stringValue = prefillName
        nameField.bezelStyle = .roundedBezel

        let minutesField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        minutesField.placeholderString = "Minutes (e.g. 50)"
        minutesField.stringValue = prefillMinutes
        minutesField.bezelStyle = .roundedBezel

        container.addSubview(nameField)
        container.addSubview(minutesField)
        alert.accessoryView = container

        // Focus the first empty field.
        alert.window.initialFirstResponder = prefillName.isEmpty ? nameField : minutesField

        let response = alert.runModal()
        switch response {
        case .alertFirstButtonReturn:
            return .submitted(name: nameField.stringValue, minutesStr: minutesField.stringValue)
        default:
            return .cancelled
        }
    }
}
