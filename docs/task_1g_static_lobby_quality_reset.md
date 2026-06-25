# Task 1G Static Lobby Quality Reset

## Purpose

Task 1G stops adding motion and resets the Home Lobby toward a clean static PC-game baseline. The previous runtime view had a too-dark background, a cheap-feeling Logo, ghostly circles behind the Logo, and neon/pulse effects that made the screen feel unstable. This pass focuses on static composition first.

Scope remains Home Lobby only. No poker table, networking, Steam, store, payment, account system, or gameplay logic was added.

## Disabled Motion / FX

Disabled or hidden in this pass:

- Logo pulse, breathing, scaling, and alpha animation.
- Procedural Logo circle / geometric backplate.
- Background flow shader layer.
- Background moving neon line layer.
- Heavy dark shade / vignette overlays.
- Play panel slide/fade reveal.
- Mode card stagger reveal.
- Mode card hover lift and scale.
- Mode card press squash/rebound.
- Daily Bonus slide-in.
- Foreground decor drift.

Retained minimal interaction:

- Left nav hover/active highlight.
- PLAY/HOME state switching.
- Mode card hover border and soft shadow highlight.

## Background

The lobby still uses the locked background:

```text
res://assets/home_lobby/backgrounds/home_background_v1.png
```

The background was not regenerated or replaced. It is rendered full-screen with aspect-cover behavior. To keep the smoke, chips, and table surface visible, the `BackgroundTexture` uses brighter Godot modulation:

```gdscript
base.modulate = Color(1.34, 1.30, 1.40, 1.0)
```

The previous flow shader and dark overlay stack were removed from runtime construction. A very light, static `BackgroundCenterLift` remains non-interactive and does not animate.

## Logo

The runtime Logo is now a static Godot text transition version:

```text
TEXAS
HOLD'EM
POKER CLUB
```

It uses layered labels for a fixed dark shadow and very light fixed glow. It does not pulse, scale, breathe, or animate.

The previous PNG logo candidate was moved to:

```text
res://assets/home_lobby/logo/rejected/a_high_resolution_graphic_logo_on_a_transparent_c_2_batch_2.png
```

It is rejected for runtime because it displays a checker background and is not a clean transparent Logo asset.

## State Layout

Collapsed launch state shows only:

- Background
- Left main menu
- Top bar
- Center static Logo
- Minimal bottom prompt

Collapsed launch state hides:

- Mode cards
- Daily Bonus
- Welcome Pack
- Play submenu
- Large panels
- Foreground decor
- Logo geometry/backplate

PLAY expanded state shows:

- Play submenu
- Five mode cards in one row
- Daily Bonus below the cards
- Welcome Pack beside the Daily Bonus

The Logo is hidden in expanded state to avoid competing with the cards.

## Left Menu Click Accuracy

Decorative layers remain `mouse_filter = IGNORE`.

Runtime non-interactive layers include:

- `BackgroundRoot`
- `BackgroundTexture`
- `BackgroundCenterLift`
- `ForegroundDecor`
- `CenterBrand`
- `LogoTextFallback`
- `CollapsedPrompt`

Left menu buttons remain actual `NavItem` `Button` nodes. Play submenu entries are actual `Button` nodes with visible hit areas. `NavItem.DEBUG_SHOW_HIT_RECTS` was added and defaults to `false`; setting it to `true` draws each main nav button rect for development inspection.

## Runtime Screenshots

Generated with:

```text
C:\godot\Godot_v4.6.2-stable_win64.exe
```

Updated real runtime screenshots:

- `docs/screenshots/runtime_collapsed_home.png`
- `docs/screenshots/runtime_play_expanded.png`

Regenerate:

```powershell
& "C:\godot\Godot_v4.6.2-stable_win64.exe" --path "C:\Users\jjbon\Documents\texas" --scene "res://scenes/screens/home_lobby_screen.tscn" --capture-lobby-state collapsed --capture-lobby-output "C:\Users\jjbon\Documents\texas\docs\screenshots\runtime_collapsed_home.png"

& "C:\godot\Godot_v4.6.2-stable_win64.exe" --path "C:\Users\jjbon\Documents\texas" --scene "res://scenes/screens/home_lobby_screen.tscn" --capture-lobby-state expanded --capture-lobby-output "C:\Users\jjbon\Documents\texas\docs\screenshots\runtime_play_expanded.png"
```

## Acceptance Notes

- Collapsed state no longer has ghost circles or geometry behind the Logo.
- Background v1 remains locked and is visibly brighter.
- Logo is static and does not pulse or scale.
- Default Home state shows only the intended minimal UI.
- PLAY is required before cards, Daily Bonus, Welcome Pack, or Play submenu appear.
- Five mode cards remain in one row.
- Daily Bonus stays below the cards.
- Hover no longer moves the mode card row.
