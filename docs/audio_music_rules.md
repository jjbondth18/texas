# Audio Music Rules

Music is managed through `scripts/services/music_service.gd`.

## Tracks

- Home/Lobby, Store, Profile, Settings, and Replay Room list/detail use `res://assets/music/bgm1.ogg`.
- Poker gameplay screens use `res://assets/music/bgm2.ogg`.

Gameplay screens include:

- Training
- Quick Play public tables
- Room Browser public tables
- Friends/private rooms
- Gem tables
- Local AI Warm-up
- ReplayPokerTableScreen fullscreen playback

## Switching

- HomeLobbyScreen requests Home BGM when the lobby loads.
- PokerTableScreen requests Table BGM in `_ready()`.
- Replay fullscreen playback requests Table BGM when the fullscreen replay overlay is shown.
- Exiting PokerTableScreen or hiding Replay fullscreen playback requests Home BGM again.

MusicService owns a single global `AudioStreamPlayer` attached to the scene tree root. If the requested track is already playing, it does not restart the stream. This prevents duplicate BGM players during hand starts, snapshots, replay steps, or next-hand transitions.

## Settings

The global BGM player uses the `Music` audio bus. `SettingsService` applies:

- `master_volume`
- `music_volume`
- `mute_all`

No gameplay screen should create its own independent BGM player.
