# Task 1E Home Lobby Lockdown

## Runtime Validation

- Godot executable used: `C:\godot\Godot_v4.6.2-stable_win64.exe`
- Project path: `C:\Users\jjbon\Documents\texas`
- Branch: `task-1e-home-lobby-lockdown`
- Real runtime screenshots regenerated:
  - `docs/screenshots/runtime_collapsed_home.png`
  - `docs/screenshots/runtime_play_expanded.png`

The screenshots were generated with the real Godot executable, not from the static reference images.

## Locked Background

The Home Lobby now directly uses:

```text
res://assets/home_lobby/backgrounds/home_background_v1.png
```

This is the hard-locked main background for the lobby. The implementation does not generate, replace, or guess alternate background art. It is rendered by `BackgroundTexture` as a full-viewport `TextureRect` with aspect-cover behavior. The dark shade above it is light, and the neon flow layers are low alpha and non-interactive so the background remains visible.

## State Rules

Collapsed launch state shows:

- Background
- Left main navigation
- Top bar
- Center brand / Logo area
- Minimal bottom prompt

Collapsed launch state hides:

- Mode cards
- Daily Bonus
- Welcome Pack
- Play submenu
- Expanded panels

PLAY expanded state shows:

- Play submenu
- Five mode cards
- Daily Bonus
- Welcome Pack
- Background Logo reduced behind the card group

Clicking `HOME` collapses back to the default cinematic home state.

## Click / Input Fixes

The click mismatch issue was addressed by keeping decorative layers non-interactive and making the Play submenu use real buttons instead of passive text labels.

Layers set to ignore mouse input include:

- `BackgroundRoot`
- `BackgroundTexture`
- `BackgroundLiftLayer`
- `BackgroundShade`
- `BackgroundFlowLayer`
- `BackgroundShaderFlow`
- `ForegroundDecor`
- `CenterBrand`
- `LogoGlow`
- `LogoImage`
- `LogoTextFallback`
- `CollapsedPrompt`

The interactive left rail remains composed of `NavItem` buttons. The Play submenu now emits `play_submenu_selected(id)` from actual `Button` nodes with visible 190x24 hit areas.

## Neon Effects Confirmed

- Background Flow Glow: visible purple/blue/magenta slow-flow layer above the locked background and below UI.
- Logo Glow Pulse: layered text Logo and procedural glow pulse subtly over time.
- Menu Hover Highlight: nav item text brightens with a smooth left indicator and background highlight.
- Mode Card Hover Glow: hover only moves internal `CardVisual`, with glow, lift, and slight scale. The outer card remains container-managed, preventing row jump.

## Logo Status

The current Logo is a transition Godot text Logo, built from layered labels:

- `LogoMain`
- `LogoMainGlowPink`
- `LogoMainGlowCyan`
- `LogoSub`
- `LogoSubGlow`

`LogoImage` remains in the `CenterBrand` container for future replacement with a clean transparent Logo texture. It is currently hidden because the supplied PNG displays a checker background in runtime.

## Screenshot Commands

```powershell
& "C:\godot\Godot_v4.6.2-stable_win64.exe" --path "C:\Users\jjbon\Documents\texas" --scene "res://scenes/screens/home_lobby_screen.tscn" --capture-lobby-state collapsed --capture-lobby-output "C:\Users\jjbon\Documents\texas\docs\screenshots\runtime_collapsed_home.png"

& "C:\godot\Godot_v4.6.2-stable_win64.exe" --path "C:\Users\jjbon\Documents\texas" --scene "res://scenes/screens/home_lobby_screen.tscn" --capture-lobby-state expanded --capture-lobby-output "C:\Users\jjbon\Documents\texas\docs\screenshots\runtime_play_expanded.png"
```

If the PNG resources have just been added on a fresh checkout, run one import pass first:

```powershell
& "C:\godot\Godot_v4.6.2-stable_win64.exe" --path "C:\Users\jjbon\Documents\texas" --headless --import
```

## Acceptance Notes

- Lobby background is locked to `backgrounds/v1`.
- Default homepage is collapsed.
- Mode cards, Daily Bonus, Welcome Pack, and Play submenu are hidden until `PLAY`.
- Left menu click areas align with visible buttons.
- Decorative layers do not swallow mouse input.
- Five mode cards remain in a stable row.
- Hover no longer moves the whole layout row.
- Runtime screenshots were updated from real Godot execution.
