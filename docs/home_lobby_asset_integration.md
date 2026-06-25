# Home Lobby Asset Integration

Task 1A integrates user-provided rectangular assets into the existing Home Lobby vertical slice. Scope remains lobby-only: no poker table, networking, Steam API, store, payments, accounts, or gameplay logic.

## Integrated Assets

### Background

- `res://assets/home_lobby/backgrounds/home_background.png`
  - Full-screen Home Lobby background.
  - Rendered through a Godot `TextureRect`.
  - A subtle dark overlay and low-alpha shader flow sit above it.

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
- Central `TEXAS HOLD'EM` logo text.
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

- Logo is still Godot text and procedural spade/glow, pending final brand asset.
- Top bar avatar and icons are still simple placeholders.
- Daily Bonus rewards are mock data.
- Mode card art is user-provided current placeholder art and can be replaced at the same paths.

## Screenshot Status

- `docs/screenshots/collapsed_home.png`
- `docs/screenshots/play_expanded.png`

These are static visual references generated outside the Godot runtime because this environment does not expose a Godot executable on PATH. They are not real Godot runtime screenshots.
