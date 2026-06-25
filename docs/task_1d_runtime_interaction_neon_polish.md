# Task 1D Runtime Interaction And Neon Polish

## User-Reported Problems

Runtime screenshots and user testing after Task 1C exposed these issues:

- Hovering a ModeCard could make cards jump left.
- The background still felt too dark, so the neon poker club atmosphere was not visible enough.
- The expanded card group needed to remain stable and unified.
- The lobby needed more real neon motion/lighting polish without becoming noisy.

## ModeCard Hover Jump Fix

Root cause:

- `ModeCard` was inside an `HBoxContainer`.
- Hover, press, and reveal tweens changed the outer card's `position` / layout-related state.
- Containers own child layout, so manually tweening the outer Control fought the container and caused cards to jump.

Fix:

- Added an internal `CardVisual` wrapper inside `ModeCard`.
- The outer `ModeCard` now stays under container layout control.
- Hover, press, shadow, border glow, scale, and reveal animations only affect `CardVisual`.
- Stagger reveal now calls `ModeCard.tween_visual_reveal()` and no longer changes the outer card position.

Validation:

- A runtime hover capture was generated during development with `--capture-lobby-hover-index 2`.
- The hovered Tournaments card lit up and lifted slightly while the full row stayed in place.
- The temporary hover validation image was removed from deliverables.

## Background And Neon Polish

Task 1D changed the background stack:

- The rectangular `home_background.png` remains the full-screen base layer.
- Background `TextureRect` modulate was increased to brighten the source art.
- The black shade overlay is now fully transparent.
- Flow shader alpha is reduced to `0.03` so it adds motion without darkening the background.
- Added `BackgroundLiftLayer` to softly lift the center, right bar area, and lower table region.
- Added `BackgroundFlowLayer` with slow blue/magenta line glow and a very soft moving color bloom.

The result is still dark and premium, but the right-side table/bar, purple-blue smoke, and lower tabletop are easier to read.

## Expanded Layout

- Left nav remains fixed at 280px.
- Main content begins at x = 360px.
- `CHOOSE YOUR ROOM`, the five mode cards, and Daily Bonus all stay in the main safe area.
- Cards remain one unified row and do not enter the left nav area.
- Expanded logo stays as a low-alpha background watermark and does not compete with cards.

## Top Bar Polish

- `EXIT` remains in the top bar.
- Icon buttons retain hover glow.
- Currency pills now get a subtle hover border/shadow.
- Avatar and small icons are still placeholders for future replacement.

## Runtime Screenshots

Generated with real Godot runtime:

```text
docs/screenshots/runtime_collapsed_home.png
docs/screenshots/runtime_play_expanded.png
```

Command pattern:

```powershell
& "C:\godot\Godot_v4.6.2-stable_win64.exe" --path "C:\Users\jjbon\Documents\texas" --scene "res://scenes/screens/home_lobby_screen.tscn" --capture-lobby-state collapsed --capture-lobby-output "C:\Users\jjbon\Documents\texas\docs\screenshots\runtime_collapsed_home.png"

& "C:\godot\Godot_v4.6.2-stable_win64.exe" --path "C:\Users\jjbon\Documents\texas" --scene "res://scenes/screens/home_lobby_screen.tscn" --capture-lobby-state expanded --capture-lobby-output "C:\Users\jjbon\Documents\texas\docs\screenshots\runtime_play_expanded.png"
```

Do not use `--headless` for screenshots; Godot's dummy renderer cannot provide a readable viewport texture.

## Interaction Validation

- HOME / PLAY state switching is stable.
- Expanded mode cards remain in a single row.
- ModeCard hover no longer changes outer layout position.
- ModeCard press only squashes the internal visual wrapper.
- `Esc` exits the running development window.
- Top bar `EXIT` exits the running development window.
- `Alt+Enter` toggles windowed/fullscreen mode.

## Still Not Implemented

- No poker table.
- No networking.
- No Steam integration.
- No store, payments, account system, or gameplay logic.
