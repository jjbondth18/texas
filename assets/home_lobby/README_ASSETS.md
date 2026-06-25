# Home Lobby Assets

All files in this folder are user-provided rectangular assets for the Home/Lobby vertical slice. They are treated as replaceable art assets, not baked UI.

## Background

- `backgrounds/home_background.png`
  - Source: user-provided asset.
  - Use: full-screen Home Lobby atmospheric background.
  - Status: current production placeholder, replaceable later.

## Mode Cards

- `mode_cards/mode_quick_play.png`
  - Source: user-provided asset.
  - Use: Quick Play card illustration.
  - Status: current production placeholder, replaceable later.

- `mode_cards/mode_cash_tables.png`
  - Source: user-provided asset.
  - Use: Cash Tables card illustration.
  - Status: current production placeholder, replaceable later.

- `mode_cards/mode_tournaments.png`
  - Source: user-provided asset.
  - Use: Tournaments card illustration.
  - Status: current production placeholder, replaceable later.

- `mode_cards/mode_private_table.png`
  - Source: user-provided asset.
  - Use: Private Table card illustration.
  - Status: current production placeholder, replaceable later.

- `mode_cards/mode_club_games.png`
  - Source: user-provided asset.
  - Use: Club Games card illustration.
  - Status: current production placeholder, replaceable later.

## Foreground

- `foreground/foreground_decor_strip.png`
  - Source: user-provided asset.
  - Use: low-opacity bottom foreground decor layer.
  - Status: current production placeholder, replaceable later.

## How To Replace

Replace a PNG with a new file at the same path and reopen Godot, or update the `"image"` path in `res://scripts/data/mock_home_data.gd` for mode-card images. The background and foreground paths are referenced in `res://scripts/screens/home_lobby_screen.gd`.
