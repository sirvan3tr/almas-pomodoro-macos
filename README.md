# Almas Pomodoro

A tiny native macOS menu-bar Pomodoro timer.

- Purple, clearly legible countdown pill in the menu bar while running.
- Silent when it finishes — no sound, no modal. The pill just **flashes**
  between two distinct colours so a glance tells you it's done.
- User-defined custom timers are persisted locally.

Built as a plain SwiftPM executable (no Xcode project required) so the
edit→build→launch loop stays short via the `Makefile`.

## Quick start

```bash
make dev      # debug build, kill old instance, launch fresh
make test     # run XCTest suite
make app      # package a minimal .app bundle under .build/
make install  # copy .app into ~/Applications
make link     # symlink ~/.local/bin/almaspom (the CLI)
make help     # see all targets
```

Once linked:

```bash
almaspom 25m -i "Write 10 emails"
almaspom preset Pomodoro
almaspom status
almaspom stop
```

## Docs

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — module boundaries and state model.
- [docs/BUILD.md](docs/BUILD.md) — build/run/packaging details.
- [docs/USAGE.md](docs/USAGE.md) — menu-bar UX, keyboard shortcuts, data.
- [docs/CLI.md](docs/CLI.md) — `almaspom` command grammar and IPC format.
- [AGENTS.md](AGENTS.md) — design principles this project is held to.

## Requirements

- macOS 13 (Ventura) or newer
- Swift 5.9+ toolchain (ships with Xcode 15 / Command Line Tools)
