import Foundation

/// Pure, value-typed state for the Pomodoro timer.
///
/// Deliberately exhaustive: every UI state the app can be in is one of
/// these cases. No invalid combinations representable.
enum TimerState: Equatable {
    case idle
    case running(preset: Preset, remaining: Int)
    case finished(preset: Preset)

    var isRunning: Bool {
        if case .running = self { return true }
        return false
    }

    var isFinished: Bool {
        if case .finished = self { return true }
        return false
    }

    var activePreset: Preset? {
        switch self {
        case .idle: return nil
        case .running(let p, _): return p
        case .finished(let p): return p
        }
    }
}
