# Architecture

Small files, narrow responsibilities, one explicit state machine. The app
is decomposed so each piece is testable in isolation before composition.

## Module map

```
Sources/AlmasPomodoro/
├── main.swift                 # NSApplication bootstrap (accessory policy)
├── App/
│   └── AppDelegate.swift      # App lifecycle + AppActions dispatch
├── Timer/
│   ├── Session.swift          # preset + optional intent + startedAt
│   ├── TimerState.swift       # pure value type: idle | running | finished
│   └── PomodoroTimer.swift    # countdown engine, push-based onChange
├── MenuBar/
│   ├── StatusItemStyle.swift  # colour + layout tokens (data, not behaviour)
│   ├── StatusItemRenderer.swift # renders TimerState → NSStatusItem button
│   ├── MenuBuilder.swift      # pure constructor: state + presets → NSMenu
│   ├── AddPresetDialog.swift  # modal for collecting custom-preset input
│   └── IntentDialog.swift     # prompt at session start (Start/Skip/Cancel)
├── Presets/
│   ├── Preset.swift           # value type with enforced invariants
│   ├── PresetStore.swift      # JSON persistence (atomic, quarantines corrupt)
│   └── AnyCodable.swift       # forward-compatible round-tripping
└── Support/
    └── Formatting.swift       # MM:SS and short-duration helpers
```

## State model

The one and only state variable the UI observes is `TimerState`:

```swift
struct Session {
    let preset: Preset
    let intent: String?   // nil = skipped; non-nil = trimmed, non-empty
    let startedAt: Date
}

enum TimerState {
    case idle
    case running(session: Session, remaining: Int)
    case finished(session: Session)
}
```

`Session` exists so forward-compatible additions (tags, history, focus-mode
flags) live on the struct instead of mutating enum case arities.

The menu bar's appearance is a **pure function** of that state:

| State       | Background                           | Content                |
|-------------|--------------------------------------|------------------------|
| `.idle`     | none (template `timer` SF Symbol)    | standard tint          |
| `.running`  | **purple pill**                      | `MM:SS` in white       |
| `.finished` | alternating **orange ↔ red** flash   | "<preset> done" in white |

No sound is played in any state. The finish cue is purely visual, by design.

## Data flow

1. User opens the menu → `AppDelegate.menuNeedsUpdate` asks `MenuBuilder`
   for a fresh menu computed from `(state, presets)`.
2. User picks a preset → `AppDelegate.startPresetFromMenu` presents
   `IntentDialog` (Start / Skip / Cancel). The dialog returns a
   strongly-typed `Outcome`, constructed only after the intent has been
   round-tripped through `Session.normalize`.
3. On confirm/skip, a `Session` is built and passed to
   `PomodoroTimer.start`.
4. `PomodoroTimer` emits every state change via `onChange`, which
   `StatusItemRenderer.render` consumes.
5. On hitting zero the timer transitions to `.finished`; the renderer
   swaps its flash animation in. The intent remains visible in the
   menu's header so the user sees what they'd committed to.
6. Clicking **Dismiss** (or pressing ↩ while the menu is open) calls
   `acknowledge()`, returning to `.idle`.

## Why this shape (per AGENTS.md)

- **Decompose before compose.** Five tiny modules, each under ~150 LOC.
- **Separate information from mechanism.** `TimerState` and `Preset` are
  the facts; `PomodoroTimer` and `StatusItemRenderer` are the mechanisms.
- **Fail fast.** `Preset.init` enforces invariants at the boundary;
  `PomodoroTimer.tick` uses a `guard case` so unexpected transitions are
  immediately visible, not silently tolerated; `PresetStore` refuses to
  silently drop corrupt data — it quarantines the file and surfaces the
  error to the caller.
- **Open-world semantics on disk.** `PresetStore` round-trips unknown
  top-level keys so future additions don't break old versions.
- **Accretion over update.** `PresetStore.append`/`.remove` never mutate
  existing entries in place; they rewrite the whole file atomically.
