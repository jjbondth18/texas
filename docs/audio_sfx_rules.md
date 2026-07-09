# Gameplay SFX Rules

Gameplay sound effects are managed through `scripts/services/sfx_manager.gd`.

## Assets

- Community card reveal: `res://assets/music/draw.wav`
- New hand shuffle: `res://assets/music/shuffle.wav`
- Chip movement and chip purchases: `res://assets/music/chip.wav`
- Gem transactions: `res://assets/music/Gem.wav`
- Hand result/win: `res://assets/music/chip_gem_win.wav`

## Bus And Settings

All gameplay SFX use the `SFX` audio bus. The existing Settings service controls this bus through the SFX volume and Mute All settings. BGM remains managed by `MusicService`; SFX changes must not create additional BGM players or alter home/table music selection.

## Trigger Rules

- `draw.wav`: community card reveal animation. Opening hole-card deal SFX is disabled to avoid stacked startup artifacts.
- `shuffle.wav`: once per new hand, and once when opening replay playback.
- `chip.wav`: blinds, call, bet, raise, all-in chip movement, Add Chips success, chip buy-in success, and mock chip purchases.
- `Gem.wav`: gem rewards or gem spending, including replay unlocks, mock gem purchases, and Daily Bonus gem rewards.
- `chip_gem_win.wav`: once when a hand reaches result/showdown/winner state.

`check`, `fold`, waiting states, snapshot refreshes, and replay step redraws must not trigger chip SFX.

## Shuffle Playback

Shuffle SFX is enabled again after disabling stacked hole-card deal SFX at hand start. It remains guarded to keep the sound clean:

- fixed `pitch_scale = 1.0`
- no looping
- import compression disabled for `assets/music/shuffle.wav.import`
- default volume `-12 dB`
- hand-scoped event ids prevent repeated shuffle sounds on snapshot refresh
- if a shuffle sound is already playing, duplicate shuffle requests are ignored

If electrical/compressed artifacts return, disable shuffle before changing unrelated SFX.

## Duplicate Prevention

Every event-triggered sound should provide a stable event id:

- table visual event id for card/chip animation events
- server action sequence for authoritative playback events
- hand id for shuffle and hand result sounds
- replay id plus step index for replay playback sounds
- transaction-style ids for wallet/profile events

Refreshing a snapshot, rebuilding UI, or revisiting the same replay step should not replay the same SFX.
