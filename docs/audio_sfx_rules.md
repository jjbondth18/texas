# Gameplay SFX Rules

Gameplay sound effects are managed through `scripts/services/sfx_manager.gd`.

## Assets

- Card deal/reveal: `res://assets/music/draw.wav`
- New hand shuffle: `res://assets/music/shuffle.wav`
- Chip movement and chip purchases: `res://assets/music/chip.wav`
- Gem transactions: `res://assets/music/Gem.wav`
- Hand result/win: `res://assets/music/chip_gem_win.wav`

## Bus And Settings

All gameplay SFX use the `SFX` audio bus. The existing Settings service controls this bus through the SFX volume and Mute All settings. BGM remains managed by `MusicService`; SFX changes must not create additional BGM players or alter home/table music selection.

## Trigger Rules

- `draw.wav`: individual hole-card deal events and community card reveal animation.
- `shuffle.wav`: once per new hand, and once when opening replay playback.
- `chip.wav`: blinds, call, bet, raise, all-in chip movement, Add Chips success, chip buy-in success, and mock chip purchases.
- `Gem.wav`: gem rewards or gem spending, including replay unlocks, mock gem purchases, and Daily Bonus gem rewards.
- `chip_gem_win.wav`: once when a hand reaches result/showdown/winner state.

`check`, `fold`, waiting states, snapshot refreshes, and replay step redraws must not trigger chip SFX.

## Duplicate Prevention

Every event-triggered sound should provide a stable event id:

- table visual event id for card/chip animation events
- server action sequence for authoritative playback events
- hand id for shuffle and hand result sounds
- replay id plus step index for replay playback sounds
- transaction-style ids for wallet/profile events

Refreshing a snapshot, rebuilding UI, or revisiting the same replay step should not replay the same SFX.
