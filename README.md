# Neon Texas Hold'em Lobby

Godot 4.x Home/Lobby vertical slice for a premium desktop-first Steam Texas Hold'em game prototype.

This slice is UI-only. It does not implement networking, Steam API, poker gameplay, store backend, payment, or a real economy.

## Run In Godot

1. Open `C:\Users\jjbon\Documents\texas` in Godot 4.x.
2. Run the project.
3. Main scene: `res://scenes/screens/home_lobby_screen.tscn`.

Known local executable:

```powershell
& "C:\godot\Godot_v4.6.2-stable_win64.exe" --path "C:\Users\jjbon\Documents\texas" --scene "res://scenes/screens/home_lobby_screen.tscn"
```

The project is configured for a 1920x1080 desktop-first 16:9 lobby.

## State Controls

- Default launch state is collapsed cinematic home.
- Click `PLAY` in the left navigation rail to open the Play expanded state.
- Click `HOME` to return to the collapsed state.
- Press `Esc` to close the running development window.
- Click `EXIT` in the top bar to close the running development window.
- Press `Alt+Enter` to toggle windowed/fullscreen mode.
- `Alt+F4` also closes the window.
- Click a mode card to print `Selected lobby mode: <id>` in the Godot output.
- Other navigation items currently print a Coming Soon message only.

## Implemented Motion

- Slow shader-based background flow.
- Subtle Logo breathing pulse.
- Left nav hover and active indicator.
- PLAY submenu fade-in.
- Play panel fade and slide reveal.
- Mode card stagger reveal.
- Mode card hover lift, scale, border glow, and shadow.
- Mode card press compression and rebound.
- Daily Bonus slide-in.
- Subtle foreground chip/card drift.

## Task 1A Asset Integration

This project now uses user-provided rectangular lobby assets:

- Full-screen background: `res://assets/home_lobby/backgrounds/home_background.png`
- Mode card illustrations: `res://assets/home_lobby/mode_cards/*.png`
- Bottom decor strip: `res://assets/home_lobby/foreground/foreground_decor_strip.png`

The left nav, top bar, logo text, card titles/subtitles, Daily Bonus, and interactions are still rendered by Godot UI components.

See `docs/home_lobby_asset_integration.md` and `assets/home_lobby/README_ASSETS.md`.

## Screenshots

- Static reference: `docs/screenshots/static_collapsed_home.png`
- Static reference: `docs/screenshots/static_play_expanded.png`
- Runtime target: `docs/screenshots/runtime_collapsed_home.png`
- Runtime target: `docs/screenshots/runtime_play_expanded.png`

The static reference files are not real Godot runtime screenshots.

Runtime screenshots have been generated with the real Godot executable in non-headless mode. To regenerate them locally, run:

```powershell
& "C:\godot\Godot_v4.6.2-stable_win64.exe" --path "C:\Users\jjbon\Documents\texas" --scene "res://scenes/screens/home_lobby_screen.tscn" --capture-lobby-state collapsed --capture-lobby-output "C:\Users\jjbon\Documents\texas\docs\screenshots\runtime_collapsed_home.png"

& "C:\godot\Godot_v4.6.2-stable_win64.exe" --path "C:\Users\jjbon\Documents\texas" --scene "res://scenes/screens/home_lobby_screen.tscn" --capture-lobby-state expanded --capture-lobby-output "C:\Users\jjbon\Documents\texas\docs\screenshots\runtime_play_expanded.png"
```

Do not use `--headless` for screenshot capture. Godot's headless dummy renderer cannot provide a viewport texture for this scene. If automatic capture fails, run the scene normally, click `PLAY` for the expanded state, and use the OS screenshot tool to save the two runtime screenshots at the paths above.

## Audit

See `docs/home_lobby_audit.md` for the full audit against the complete project start pack and visual reference.

## Placeholder Assets

- Logo: Godot text and procedural spade/glow placeholder.
- Background: user-provided rectangular lobby background plus subtle shader flow.
- Mode cards: user-provided rectangular card illustrations with Godot-rendered text.
- Top avatar and icons: simple UI placeholders.
- Foreground decor strip: user-provided rectangular image, hidden in collapsed and very low opacity in expanded.

## Key Files

- `scenes/screens/home_lobby_screen.tscn`
- `scenes/components/top_bar.tscn`
- `scenes/components/left_nav_rail.tscn`
- `scenes/components/nav_item.tscn`
- `scenes/components/mode_card.tscn`
- `scenes/components/daily_bonus_bar.tscn`
- `scripts/screens/home_lobby_screen.gd`
- `scripts/components/top_bar.gd`
- `scripts/components/left_nav_rail.gd`
- `scripts/components/nav_item.gd`
- `scripts/components/mode_card.gd`
- `scripts/components/daily_bonus_bar.gd`
- `scripts/motion/motion_manager.gd`
- `scripts/data/mock_home_data.gd`
- `scripts/theme/home_theme.gd`
- `shaders/flow_noise_bg.gdshader`
- `shaders/neon_soft_glow.gdshader`
