import Foundation

/// Core countdown engine.
///
/// Design choices:
///   - State transitions are explicit; illegal transitions are programmer
///     errors (precondition). There is no "maybe the timer is running" —
///     the state answers the question.
///   - Time is measured against a monotonic reference (`Date` here is OK
///     for minute-scale countdowns; we use the delta between ticks, not
///     absolute wall-clock arithmetic, so clock changes don't drift us).
///   - The engine is push-based: callers subscribe via `onChange` and
///     receive the full new state on every change.
final class PomodoroTimer {

    private(set) var state: TimerState = .idle {
        didSet { if oldValue != state { onChange?(state) } }
    }

    /// Called on the main run loop whenever `state` changes.
    var onChange: ((TimerState) -> Void)?

    private var ticker: Foundation.Timer?
    private var endDate: Date?

    deinit { invalidate() }

    /// Begin a new countdown for `session`. If a timer is already running
    /// it is replaced — we treat this as an explicit override rather than
    /// a silent no-op so the caller's intent is always honoured.
    func start(_ session: Session, now: Date = Date()) {
        invalidate()
        endDate = now.addingTimeInterval(TimeInterval(session.preset.seconds))
        state = .running(session: session, remaining: session.preset.seconds)
        scheduleTicker()
    }

    /// Convenience for callers that don't care about intent tracking
    /// (e.g. tests, CLI smoke launches). Constructing a Session with a nil
    /// intent is infallible by construction (normalize shortcut-returns),
    /// so the force-try here is load-bearing documentation: if it ever does
    /// throw, Session's contract was broken and we want the crash.
    func start(_ preset: Preset, now: Date = Date()) {
        let session = try! Session(preset: preset, intent: nil, startedAt: now)
        start(session, now: now)
    }

    /// Cancel any running or finished state and return to idle.
    func stop() {
        invalidate()
        state = .idle
    }

    /// Acknowledge a finished timer, returning to idle. No-op if not finished.
    func acknowledge() {
        guard state.isFinished else { return }
        state = .idle
    }

    // MARK: - Tick

    private func scheduleTicker() {
        let t = Foundation.Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.tick(now: Date())
        }
        RunLoop.main.add(t, forMode: .common)
        ticker = t
    }

    /// Internal for tests: advance the model to the given instant.
    func tick(now: Date) {
        guard case .running(let session, _) = state, let end = endDate else { return }
        let remaining = Int(ceil(end.timeIntervalSince(now)))
        if remaining <= 0 {
            invalidate()
            state = .finished(session: session)
            return
        }
        state = .running(session: session, remaining: remaining)
    }

    private func invalidate() {
        ticker?.invalidate()
        ticker = nil
        endDate = nil
    }
}
