import AppKit

/// Renders `TimerState` onto an `NSStatusItem`'s button.
///
/// Pure sink — the only state held here is what's needed to animate the
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
        button.imageHugsTitle = true
    }

    func render(_ state: TimerState) {
        stopFlash()
        switch state {
        case .idle:
            renderIdle()
        case .running(let session, let remaining):
            renderRunning(session: session, remaining: remaining)
        case .finished(let session):
            renderFinished(session: session)
        }
    }

    // MARK: - Idle

    private func renderIdle() {
        guard let button = statusItem.button else { return }
        button.layer?.backgroundColor = NSColor.clear.cgColor
        button.contentTintColor = nil
        button.attributedTitle = NSAttributedString(string: "")
        button.toolTip = "Almas Pomodoro"
        button.imagePosition = .imageOnly
        button.image = Icons.idleStatusBar()
    }

    // MARK: - Running

    private func renderRunning(session: Session, remaining: Int) {
        guard let button = statusItem.button else { return }
        let total = session.preset.seconds
        let progress = Double(remaining) / Double(max(1, total))
        button.layer?.backgroundColor = StatusItemStyle.runningBackground.cgColor
        button.contentTintColor = StatusItemStyle.runningForeground
        button.image = Icons.runningPill(progress: progress)
        button.imagePosition = .imageLeading
        button.attributedTitle = Self.pillTitle(
            text: " \(Formatting.clock(remaining))",
            color: StatusItemStyle.runningForeground,
            trailingPad: true
        )
        button.toolTip = Self.tooltip(for: session, remaining: remaining)
    }

    // MARK: - Finished

    private func renderFinished(session: Session) {
        guard let button = statusItem.button else { return }
        button.image = Icons.finishedPill()
        button.imagePosition = .imageLeading
        button.contentTintColor = StatusItemStyle.flashForeground
        button.toolTip = Self.tooltip(for: session, remaining: 0, finished: true)
        flashOn = true
        applyFlashFrame(session: session, button: button, animated: false)

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
            color: StatusItemStyle.flashForeground,
            trailingPad: false
        )
    }

    // MARK: - Lifecycle

    private func stopFlash() {
        flashTimer?.invalidate()
        flashTimer = nil
        statusItem.button?.layer?.removeAnimation(forKey: "flashBackground")
    }

    // MARK: - Helpers

    private static func pillTitle(
        text: String,
        color: NSColor,
        trailingPad: Bool
    ) -> NSAttributedString {
        let padded = trailingPad ? text + " " : text
        return NSAttributedString(
            string: padded,
            attributes: [
                .foregroundColor: color,
                .font: StatusItemStyle.pillFont
            ]
        )
    }

    private static func tooltip(
        for session: Session,
        remaining: Int,
        finished: Bool = false
    ) -> String {
        var parts: [String] = []
        if finished {
            parts.append("\(session.preset.name) — finished")
        } else {
            parts.append("\(session.preset.name) — \(Formatting.clock(remaining)) remaining")
        }
        if let intent = session.intent {
            parts.append("↳ \(intent)")
        }
        return parts.joined(separator: "\n")
    }
}
