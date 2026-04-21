# Build

This is a plain Swift Package executable — no Xcode project file. Everything
is driven through `make` for a short edit-compile-run loop.

## Prerequisites

- macOS 13+
- Swift 5.9+ (ships with Xcode 15 / recent Command Line Tools)
- Optional: `fswatch` (for `make watch`), `swift-format` (for `make fmt`/`make lint`)

Both optional tools install via Homebrew:

```bash
brew install fswatch swift-format
```

## Makefile targets

| Target         | What it does                                                  |
|----------------|----------------------------------------------------------------|
| `make` / `dev` | Debug build, kill old instance, launch fresh. Default loop.   |
| `make run`     | Same as `dev`.                                                |
| `make build`   | Debug `swift build`.                                          |
| `make release` | Optimised `swift build -c release`.                           |
| `make test`    | Run the XCTest suite.                                         |
| `make watch`   | Rebuild + relaunch on every change under `Sources/`.          |
| `make app`     | Produce `.build/AlmasPomodoro.app` (bundles Info.plist).      |
| `make install` | Copy the .app to `~/Applications/`.                            |
| `make kill`    | Terminate any running instance.                               |
| `make log`     | `tail -f /tmp/almas-pomodoro.log` (output of the running app).|
| `make clean`   | Kill + wipe `.build/`.                                        |
| `make help`    | Print the list above.                                         |

## How the "fast rebuild" loop works

`make dev` does three things in order:

1. `swift build` — incremental, typically <1s after the first build.
2. `pkill -x almas-pomodoro` — tears down the previous menu-bar item so
   you never get two purple pills.
3. Launches the fresh binary detached via `nohup`, piping to
   `/tmp/almas-pomodoro.log`.

For continuous rebuilds on save, use `make watch` (requires `fswatch`).

## Running as a .app bundle

`make app` assembles a minimal `.app` with the required keys for a menu-bar
-only app:

- `LSUIElement = true` — no Dock icon, no menu bar menu.
- `CFBundleIdentifier = sh.almas.pomodoro`.

`make install` drops that bundle into `~/Applications/` so you can launch
it from Spotlight. For global deployment, copy it to `/Applications/`
manually (requires admin).

## Why no Xcode project?

- Reproducible from a clean clone — no `.pbxproj` churn.
- Builds on any machine with the Swift toolchain; no IDE needed.
- Tests run via `swift test`, which CI can invoke trivially.
