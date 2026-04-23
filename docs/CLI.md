# CLI

`almaspom` is a CLI-first interface to the menu-bar app. Both the
terminal and the menu-bar act as clients of a single command bus — the
running GUI — so every action you can take in the menu has an equivalent
one-liner.

## Install

```bash
make link    # builds, installs the .app, symlinks ~/.local/bin/almaspom
```

If `~/.local/bin` isn't on your `PATH`, add it:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Remove with `make unlink`.

## Quick examples

```bash
almaspom                          # ensure the menu-bar app is running
almaspom 25                       # start a 25-minute timer (bare int = minutes)
almaspom 25m                      # same
almaspom 25min                    # same
almaspom 90s                      # 90-second timer
almaspom 1h30m                    # 1h 30m (tokens compose in any order)

almaspom 25m -i "Write 10 emails" # with an intent
almaspom 1h --as "Deep Work"      # label an ad-hoc timer

almaspom preset Pomodoro          # start a saved preset by name
almaspom preset "Long Break" -i "Coffee and think"

almaspom stop                     # stop the running timer
almaspom dismiss                  # acknowledge a finished timer
almaspom status                   # print the current state

almaspom presets                  # list saved presets
almaspom presets add "Deep Work" 50m
almaspom presets rm  "Deep Work"

almaspom ping                     # round-trip the GUI to check it's alive
almaspom --help
almaspom --version
```

## Duration grammar

| Form       | Meaning                                        |
|------------|-------------------------------------------------|
| `25`       | **25 minutes** — bare integers default to minutes |
| `25m`      | 25 minutes                                     |
| `25min`    | 25 minutes                                     |
| `25minutes`| 25 minutes                                     |
| `90s`      | 90 seconds                                     |
| `1h`       | 1 hour                                         |
| `1h30m`    | 1 hour 30 minutes                              |
| `25m30s`   | 25 minutes 30 seconds                          |

Case-insensitive. Bad input fails loudly — no silent fallbacks. The
ceiling is 24 hours; zero/negative is rejected.

## Auto-launch behaviour

State-changing commands (`25m`, `stop`, `preset …`, `presets add/rm`)
auto-launch the menu-bar app if it isn't running, wait up to 3 seconds
for the control port to appear, then send.

Read-only commands (`status`, `ping`) do *not* auto-launch. `status`
prints `idle` if nothing's running, so you can use it in shell scripts
without side effects.

## Exit codes

| Code | Meaning                                           |
|------|----------------------------------------------------|
| 0    | Success                                            |
| 1    | Runtime error (IPC failure, unknown preset, etc.)  |
| 2    | Bad CLI usage (unknown flag, missing arg, etc.)    |

Errors always go to `stderr`; normal output to `stdout`, so piping is
safe:

```bash
almaspom status | grep running
```

## IPC wire format

The CLI and the GUI talk over `CFMessagePort` (port name:
`sh.almas.pomodoro.control`). Messages are JSON-encoded `Command` /
`Response` values — see `Sources/AlmasPomodoro/CLI/IPC.swift`. The
format is accretion-friendly: unknown keys are ignored on decode, and
new command kinds are added as new cases rather than repurposing old
ones.
