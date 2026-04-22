import Foundation

/// Pure, value-typed state for the Pomodoro timer.
///
/// Deliberately exhaustive: every UI state the app can be in is one of
/// these cases. No invalid combinations representable.
enum TimerState: Equatable {
    case idle
    case running(session: Session, remaining: Int)
    case finished(session: Session)

    var isRunning: Bool {
        if case .running = self { return true }
        return false
    }

    var isFinished: Bool {
        if case .finished = self { return true }
        return false
    }

    var activeSession: Session? {
        switch self {
        case .idle: return nil
        case .running(let s, _): return s
        case .finished(let s): return s
        }
    }

    var activePreset: Preset? { activeSession?.preset }
}
