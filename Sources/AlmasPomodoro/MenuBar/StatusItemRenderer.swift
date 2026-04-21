import AppKit

/// Renders `TimerState` onto an `NSStatusItem`'s button.
///
/// This is a pure sink: it holds no app state beyond what is needed to
/// animate the finish flash. It is driven by `render(state:)`.
@MainActor
final class StatusItemRenderer {
    private let statusItem: NSStatusItem
    private var flashTimer: Foundation.Timer?
    private var flashOn = true

    init(statusItem: NSStatusItem) {
        self.statusItem = statusItem
        configureButton()
    }

    private func configureButton() {
        guard let button = statusItem.button else { return }
        button.wantsLayer = true
        button.layer?.cornerRadius = StatusItemStyle.cornerRadius
        button.layer?.masksToBounds = true
        button.imagePosition = .noImage
        button.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .semibold)
    }

    func render(_ state: TimerState) {
        stopFlash()
        switch state {
        case .idle:
            renderIdle()
        case .running(_, let remaining):
            renderRunning(remaining: remaining)
        case .finished(let preset):
            renderFinished(preset: preset)
        }
    }

    // MARK: - Renders

    private func renderIdle() {
        guard let button = statusItem.button else { return }
        button.layer?.backgroundColor = NSColor.clear.cgColor
        let img = NSImage(
            systemSymbolName: "timer",
            accessibilityDescription: "Almas Pomodoro — idle"
        )
        img?.isTemplate = true
        button.image = img
        button.imagePosition = .imageOnly
        button.attributedTitle = NSAttributedString(string: "")
    }

    private func renderRunning(remaining: Int) {
        guard let button = statusItem.button else { return }
        button.image = nil
        button.imagePosition = .noImage
        button.layer?.backgroundColor = StatusItemStyle.runningBackground.cgColor
        button.attributedTitle = Self.title(
            text: " \(Formatting.clock(remaining)) ",
            color: StatusItemStyle.runningForeground
        )
    }

    private func renderFinished(preset: Preset) {
        guard let button = statusItem.button else { return }
        button.image = nil
        button.imagePosition = .noImage
        flashOn = true
        applyFlashFrame(label: preset.name, button: button)
        // Timer fires on the main run loop, so we're always on the main actor
        // at callback time. `assumeIsolated` encodes that invariant rather
        // than silently hopping threads.
        let t = Foundation.Timer(
            timeInterval: StatusItemStyle.flashInterval,
            repeats: true
        ) { [weak self, weak button] _ in
            MainActor.assumeIsolated {
                guard let self, let button else { return }
                self.flashOn.toggle()
                self.applyFlashFrame(label: preset.name, button: button)
            }
        }
        RunLoop.main.add(t, forMode: .common)
        flashTimer = t
    }

    private func applyFlashFrame(label: String, button: NSStatusBarButton) {
        let bg = flashOn
            ? StatusItemStyle.flashOnBackground
            : StatusItemStyle.flashOffBackground
        button.layer?.backgroundColor = bg.cgColor
        button.attributedTitle = Self.title(
            text: " \(label) done ",
            color: StatusItemStyle.flashForeground
        )
    }

    private func stopFlash() {
        flashTimer?.invalidate()
        flashTimer = nil
    }

    private static func title(text: String, color: NSColor) -> NSAttributedString {
        NSAttributedString(
            string: text,
            attributes: [
                .foregroundColor: color,
                .font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .semibold)
            ]
        )
    }
}
