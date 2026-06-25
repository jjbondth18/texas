# Home Lobby Asset Integration

Task 1A integrated user-provided rectangular assets into the existing Home Lobby vertical slice. Task 1E now locks the Home Lobby background to the final user-provided v1 background. Scope remains lobby-only: no poker table, networking, Steam API, store, payments, accounts, or gameplay logic.

## Integrated Assets

### Background

- `res://assets/home_lobby/backgrounds/home_background_v1.png`
  - Locked full-screen Home Lobby background for Task 1E.
  - Rendered through a Godot `TextureRect`.
  - Uses aspect-cover behavior.
  - A light non-interactive overlay and low-alpha shader flow sit above it.
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
- Central transition `TEXAS HOLD'EM` logo text, with a hidden `LogoImage` replacement container for a later clean logo asset.
- Mode card glass panels, titles, subtitles, hover and press states.
- Daily Bonus bar.
- Shader flow and motion tweens.

## Motion Implemented

- Background low-alpha shader flow.
- Logo breathing pulse.
- Left nav hover highlight and active indicator.
- PLAY area fade/slide reveal.
- Five mode cards stagger in.
- Mode card hover lift, scale, border glow, and shadow.
- Mode card press compression and rebound.
- Daily Bonus slide-in and hover cell highlight.
- Foreground decor strip slow drift.

## Still Placeholder

- Logo is a layered Godot text transition version. The supplied logo PNG is imported but hidden because it includes a visible checker background in runtime.
- Top bar avatar and icons are still simple placeholders.
- Daily Bonus rewards are mock data.
- Mode card art is user-provided current placeholder art and can be replaced at the same paths.

## Screenshot Status

- `docs/screenshots/static_collapsed_home.png`
- `docs/screenshots/static_play_expanded.png`

These are static visual references generated outside the Godot runtime. Real runtime screenshots are now stored separately as `runtime_collapsed_home.png` and `runtime_play_expanded.png`.
