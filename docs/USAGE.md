# Usage

## Interaction

Click the menu-bar item (idle icon or coloured pill) to open the menu.

From the menu you can:

- **Start** any preset. You'll be asked for a one-line **intent** for the
  session (e.g. "Write 10 emails"). Three choices:
  - **Start** — begins the timer with that intent.
  - **Skip** — begins the timer with no intent recorded.
  - **Cancel** (or Esc) — aborts, nothing starts.
  The intent is shown in the menu header while the session runs and when
  it finishes, so a glance at the menu reminds you what you set out to do.
- **Add custom timer…** (⌘N) — opens a dialog asking for a name and a
  whole number of minutes. Validation runs at submit; any error is shown
  in-place so you can correct it without losing input.
- **Remove preset** — submenu to delete a saved preset.
- **Stop timer** (⌘.) — while running, returns to idle.
- **Dismiss** (↩) — while flashing, acknowledges the finish.
- **Launch at login** — toggle under *Settings*. Uses
  `SMAppService.mainApp` and only operates when the app is running from
  the installed `.app` bundle (i.e. after `make install`).
- **Quit Almas Pomodoro** (⌘Q).

## Visual states

| State    | Menu-bar appearance                                              |
|----------|------------------------------------------------------------------|
| Idle     | Standard `timer` SF Symbol, no fill.                             |
| Running  | **Purple** pill with a small variable-fill timer ring whose ring drains as time elapses, plus a white `MM:SS` countdown next to it. |
| Finished | Crossfading **amber ↔ indigo** pill every 0.6s with a bell icon and a `<preset> done` label. |

**No sound is ever played.** The finish cue is visual only — matching the
brief: "simply flash the top bar with a different color when the timer has
finished."

### Why amber ↔ indigo?

The flash pair was deliberately chosen to remain distinguishable for
red/green-deficient users (the most common form of colour blindness,
~8% of men): amber and indigo differ in both hue and luminance across
protanopia, deuteranopia, and tritanopia. Both colours are
`NSColor.system*` variants so they adapt automatically to light/dark
appearance.

Flashing stops the moment you pick **Dismiss**, **Stop timer**, or start a
new preset.

## Data location

Custom presets live at:

```
~/Library/Application Support/AlmasPomodoro/presets.json
```

The file is JSON, human-editable. If it becomes unreadable (malformed
JSON, missing keys) the app refuses to silently discard your data: the
file is renamed with a `corrupt-<unix-ts>` suffix and the app reports the
error. You can inspect the quarantined file, recover what you need, and
restart the app — which will seed a fresh file from the classic defaults.

### On-disk schema

```json
{
  "presets": [
    { "id": "…UUID…", "name": "Pomodoro",    "seconds": 1500 },
    { "id": "…UUID…", "name": "Short Break", "seconds":  300 },
    { "id": "…UUID…", "name": "Long Break",  "seconds":  900 }
  ]
}
```

Unknown top-level keys are **preserved** on read and re-emitted on write
so future versions can add fields without breaking older installs.

## Keyboard shortcuts (while menu is open)

| Action        | Shortcut |
|---------------|----------|
| Add custom…   | ⌘N       |
| Stop timer    | ⌘.       |
| Dismiss       | ↩        |
| Quit          | ⌘Q       |
