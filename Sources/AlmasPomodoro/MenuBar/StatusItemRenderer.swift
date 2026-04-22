import AppKit

/// Renders `TimerState` onto an `NSStatusItem`'s button.
///
/// Pure sink — holds no app state beyond what is needed to animate the
/// finish flash. Driven by `render(state:)`; every call tears down any
/// previous animation before applying a new frame.
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
        button.font = StatusItemStyle.pillFont
        // Slightly larger touch/click target than the default text-only size.
        button.imagePosition = .imageOnly
    }

    func render(_ state: TimerState) {
        stopFlash()
        switch state {
        case .idle:
            renderIdle()
        case .running(_, let remaining):
            renderRunning(remaining: remaining)
        case .finished(let session):
            renderFinished(session: session)
        }
    }

    // MARK: - Idle

    private func renderIdle() {
        guard let button = statusItem.button else { return }
        button.layer?.backgroundColor = NSColor.clear.cgColor
        button.attributedTitle = NSAttributedString(string: "")
        button.imagePosition = .imageOnly
        button.image = Icons.idleStatusBar()
        button.contentTintColor = nil
    }

    // MARK: - Running

    private func renderRunning(remaining: Int) {
        guard let button = statusItem.button else { return }
        button.image = nil
        button.imagePosition = .noImage
        button.layer?.backgroundColor = StatusItemStyle.runningBackground.cgColor
        button.attributedTitle = Self.pillTitle(
            text: " \(Formatting.clock(remaining)) ",
            color: StatusItemStyle.runningForeground
        )
    }

    // MARK: - Finished

    private func renderFinished(session: Session) {
        guard let button = statusItem.button else { return }
        button.image = nil
        button.imagePosition = .noImage
        flashOn = true
        applyFlashFrame(session: session, button: button, animated: false)

        // A repeating timer + CABasicAnimation gives us a smooth crossfade
        // between the two flash colours rather than a jarring hard toggle.
        let t = Foundation.Timer(
            timeInterval: StatusItemStyle.flashInterval,
            repeats: true
        ) { [weak self, weak button] _ in
            MainActor.assumeIsolated {
                guard let self, let button else { return }
                self.flashOn.toggle()
                self.applyFlashFrame(session: session, button: button, animated: true)
            }
        }
        RunLoop.main.add(t, forMode: .common)
        flashTimer = t
    }

    private func applyFlashFrame(session: Session, button: NSStatusBarButton, animated: Bool) {
        let bg = flashOn
            ? StatusItemStyle.flashOnBackground
            : StatusItemStyle.flashOffBackground
        if animated, let layer = button.layer {
            let anim = CABasicAnimation(keyPath: "backgroundColor")
            anim.fromValue = layer.presentation()?.backgroundColor ?? layer.backgroundColor
            anim.toValue = bg.cgColor
            anim.duration = StatusItemStyle.flashCrossfade
            anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            layer.add(anim, forKey: "flashBackground")
        }
        button.layer?.backgroundColor = bg.cgColor

        button.attributedTitle = Self.pillTitle(
            text: " \(session.preset.name) done ",
            color: StatusItemStyle.flashForeground
        )
    }

    // MARK: - Lifecycle

    private func stopFlash() {
        flashTimer?.invalidate()
        flashTimer = nil
        statusItem.button?.layer?.removeAnimation(forKey: "flashBackground")
    }

    private static func pillTitle(text: String, color: NSColor) -> NSAttributedString {
        NSAttributedString(
            string: text,
            attributes: [
                .foregroundColor: color,
                .font: StatusItemStyle.pillFont
            ]
        )
    }
}
