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
- **Quit Almas Pomodoro** (⌘Q).

## Visual states

| State     | Menu-bar appearance                                        |
|-----------|-------------------------------------------------------------|
| Idle      | Standard `timer` SF Symbol, no fill.                        |
| Running   | **Purple** pill with white `MM:SS` countdown.               |
| Finished  | Alternating **orange ↔ red** flash every 0.5s with a label. |

**No sound is ever played.** The finish cue is visual only — matching the
brief: "simply flash the top bar with a different color when the timer has
finished."

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
