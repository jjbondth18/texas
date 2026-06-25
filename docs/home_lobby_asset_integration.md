# Home Lobby Asset Integration

Task 1A integrated user-provided rectangular assets into the existing Home Lobby vertical slice. Task 1G keeps the final user-provided v1 background locked while resetting the lobby to a clean static quality baseline. Scope remains lobby-only: no poker table, networking, Steam API, store, payments, accounts, or gameplay logic.

## Integrated Assets

### Background

- `res://assets/home_lobby/backgrounds/home_background_v1.png`
  - Locked full-screen Home Lobby background for Task 1G.
  - Rendered through a Godot `TextureRect`.
  - Uses aspect-cover behavior.
  - Brightened in Godot through `TextureRect.modulate`.
  - Background flow and unstable neon FX are disabled for the static reset.
  - This file should not be replaced, regenerated, or swapped during the Home Lobby lockdown pass.

### Mode Card Illustrations

- `res://assets/home_lobby/mode_cards/mode_quick_play.png`
  - Quick Play illustration.
- `res://assets/home_lobby/mode_cards/mode_cash_tables.png`
  - Cash Tables illustration.
- `res://assets/home_lobby/mode_cards/mode_tournaments.png`
  - Tournaments illustration.
- `res://assets/home_lobby/mode_cards/mode_private_table.png`
  - Private Table illustration.
- `res://assets/home_lobby/mode_cards/mode_club_games.png`
  - Club Games illustration.

Each image is displayed inside `ModeCard` using `TextureRect`. Titles and subtitles remain Godot `Label` nodes driven by `res://scripts/data/mock_home_data.gd`.

### Foreground Decor

- `res://assets/home_lobby/foreground/foreground_decor_strip.png`
  - Bottom foreground decoration layer.
  - Rendered above the background and below main UI.
  - Uses low opacity and subtle drift so it does not block cards or Daily Bonus.

## Godot-Rendered UI

The following remain Godot components, not baked images:

- Left navigation rail and nav hover/active states.
- Top player/currency bar.
- Central static transition `TEXAS HOLD'EM` logo text.
- Mode card glass panels, titles, subtitles, and subtle hover border states.
- Daily Bonus bar.
- Minimal menu hover interaction.

## Motion Implemented

- Left nav hover highlight and active indicator.
- PLAY/HOME state switching.
- Mode card hover border and soft shadow highlight.

All non-essential motion is disabled in Task 1G: background shader flow, Logo pulse, panel slide, card stagger, card lift/scale, press squash, Daily Bonus slide, and foreground drift.

## Still Placeholder

- Logo is a static layered Godot text transition version. The supplied logo PNG was moved to `assets/home_lobby/logo/rejected/` because it includes a visible checker background in runtime.
- Top bar avatar and icons are still simple placeholders.
- Daily Bonus rewards are mock data.
- Mode card art is user-provided current placeholder art and can be replaced at the same paths.

## Screenshot Status

- `docs/screenshots/static_collapsed_home.png`
- `docs/screenshots/static_play_expanded.png`

These are static visual references generated outside the Godot runtime. Real runtime screenshots are now stored separately as `runtime_collapsed_home.png` and `runtime_play_expanded.png`.
