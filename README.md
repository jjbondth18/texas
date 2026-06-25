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

## Current Interaction Baseline

Task 1G intentionally disables non-essential motion so the Home Lobby can settle into a clean static quality baseline.

Currently retained:

- Left nav hover/active highlight.
- Click `PLAY` / `HOME` state switching.
- Mode card hover border/soft shadow highlight.

Currently disabled:

- Background flow shader and unstable neon FX layers.
- Logo breathing, scaling, pulse, and procedural circle/geometry backplate.
- Play panel slide/stagger reveal.
- Mode card hover lift/scale and press squash.
- Daily Bonus slide-in.
- Foreground chip/card drift.

## Task 1G Static Lobby Quality Reset

Task 1G resets the lobby to a static, readable, desktop-first Home screen:

- Full-screen locked background: `res://assets/home_lobby/backgrounds/home_background_v1.png`
- Mode card illustrations: `res://assets/home_lobby/mode_cards/*.png`
- Rejected checker-background Logo PNG: `res://assets/home_lobby/logo/rejected/a_high_resolution_graphic_logo_on_a_transparent_c_2_batch_2.png`

The project does not generate, swap, or guess replacement lobby backgrounds. The v1 background is rendered full-screen with aspect-cover behavior and brightened in Godot through `TextureRect.modulate` so the smoke, table surface, and chips remain visible.

Default launch state is collapsed and shows only the background, left main menu, top bar, central brand, and bottom prompt. Mode cards, Daily Bonus, Welcome Pack, and the Play submenu are hidden until `PLAY` is clicked.

The left nav, top bar, static transition text Logo, card titles/subtitles, Daily Bonus, and interactions are still rendered by Godot UI components. The rejected Logo PNG is not used at runtime because it contains a visible checker background.

See `docs/task_1g_static_lobby_quality_reset.md`, `docs/home_lobby_asset_integration.md`, and `assets/home_lobby/README_ASSETS.md`.

## Task 1D Runtime Fixes

Task 1D fixed the runtime ModeCard hover jump by moving all hover/press/reveal motion to an internal `CardVisual` wrapper. The outer `ModeCard` remains controlled by the layout container, so hover no longer changes card layout position.

Task 1D also brightened the lobby background, added a subtle `BackgroundFlowLayer` / lift layer, polished neon card borders, and regenerated real runtime screenshots with:

```text
C:\godot\Godot_v4.6.2-stable_win64.exe
```

See `docs/task_1d_runtime_interaction_neon_polish.md`.

## Task 1G Runtime Fixes

Task 1G keeps the stable `CardVisual` hover model, but removes the card lift/scale motion. It locks the lobby to `home_background_v1.png`, removes the ghostly Logo backplate, disables background flow/pulse/drift motion, converts the runtime Logo to a static Godot text transition version, and regenerates real Godot runtime screenshots.

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

- Logo: static Godot text transition version with deep shadow and a very light fixed glow.
- Rejected Logo PNG: moved to `assets/home_lobby/logo/rejected/` because it is not truly transparent in runtime.
- Background: locked user-provided `home_background_v1.png`, brightened in Godot, with motion FX disabled.
- Mode cards: user-provided rectangular card illustrations with Godot-rendered text.
- Top avatar and icons: simple UI placeholders.
- Foreground decor strip: user-provided rectangular image, currently hidden for the static quality baseline.

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
