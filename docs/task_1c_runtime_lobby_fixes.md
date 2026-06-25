# Task 1C Runtime Lobby Fixes

## Runtime Screenshot Problems

User runtime screenshots showed that the lobby still had practical runtime issues:

- The running window did not have an obvious exit path.
- The Home Lobby background read too dark, making the rectangular lobby art feel almost invisible.
- In the expanded state, `CHOOSE YOUR ROOM` and the mode card group entered the left navigation area.
- The Play panel reveal tween was overriding the intended main-content safe area.
- Collapsed state needed to keep the foreground decor strip hidden to avoid a visible horizontal seam.

## Background Fix

The background file exists at:

```text
res://assets/home_lobby/backgrounds/home_background.png
```

It is rendered by a full-rect `TextureRect` in `HomeLobbyScreen`.

Task 1C changed the layers above it:

- Dark overlay alpha was reduced from `0.08` to `0.02`.
- Flow shader alpha was reduced to `0.04`.
- The flow shader now outputs transparent alpha directly, instead of acting like an opaque dark layer.

This keeps the high-quality lobby background visible while retaining a subtle animated atmosphere.

## Safe Area Fix

The left navigation rail now uses a 280px width. Main content begins at x = 360px:

```text
left nav: 0-280
main content start: 360
```

The previous Play panel reveal changed `_play_panel.position.x`, which reset the panel's left offset and caused content to overlap the left nav. Task 1C now tweens `_play_panel.offset_left` between 392px and 360px, preserving the safe area.

Mode cards are also prevented from stretching vertically by setting shrink size flags on `ModeCard`.

## Window And Exit Controls

Development runtime controls:

- `Esc`: exits the running game window.
- Top bar `EXIT`: exits the running game window.
- `Alt+Enter`: toggles windowed/fullscreen mode.
- `Alt+F4`: standard OS close.

The project is configured for windowed 1920x1080 by default, not exclusive fullscreen.

## Runtime Screenshot Workflow

Use non-headless Godot for capture:

```powershell
& "C:\godot\Godot_v4.6.2-stable_win64.exe" --path "C:\Users\jjbon\Documents\texas" --scene "res://scenes/screens/home_lobby_screen.tscn" --capture-lobby-state collapsed --capture-lobby-output "C:\Users\jjbon\Documents\texas\docs\screenshots\runtime_collapsed_home.png"

& "C:\godot\Godot_v4.6.2-stable_win64.exe" --path "C:\Users\jjbon\Documents\texas" --scene "res://scenes/screens/home_lobby_screen.tscn" --capture-lobby-state expanded --capture-lobby-output "C:\Users\jjbon\Documents\texas\docs\screenshots\runtime_play_expanded.png"
```

Headless mode was tested, but Godot's dummy renderer returned a null viewport texture, so screenshot capture must use a real display renderer.

## Generated Runtime Screenshots

- `docs/screenshots/runtime_collapsed_home.png`
- `docs/screenshots/runtime_play_expanded.png`

These were generated with:

```text
C:\godot\Godot_v4.6.2-stable_win64.exe
```

## Remaining Placeholders

- The central logo is still Godot text plus a subtle procedural spade/glow mark.
- Top bar avatar and small icons are still placeholder UI.
- Other nav destinations still print Coming Soon only.
