# Settings Structure

Settings are local player preferences for the Home/Lobby and presentation layer.

- Settings do not change wallet chips, gems, store purchases, daily bonus, avatars, or ranked profile stats.
- Settings do not change poker rules, dealing, betting, settlement, table registry behavior, or mode economy.
- Settings do not enable a real server, cloud sync, account binding, or Gem Match.
- Network, account binding, friend invite, and cloud sync controls are not shown until those systems are real enough to configure.

## Stored Fields

- `master_volume`, `music_volume`, `sfx_volume`, and `mute_all` are safe audio preferences.
- `show_hand_hints` and `confirm_big_bets` are gameplay UI preferences for future table reads.
- `animation_speed` and `reduce_motion` are local animation preferences for future UI and table animation systems.
- `ui_scale` is saved locally; current UI treats it as a future UI scale pass field.

Old settings files may contain deprecated fields such as `server_region`, `network_mode`, `cloud_sync`, `account_binding`, `allow_friend_invites`, `show_player_name`, or `window_mode`. The current settings service ignores those keys when loading and saving.

## Applied Now

The current implementation safely applies:

- Master bus volume through AudioServer.
- Music and SFX bus volume through AudioServer; if those buses are missing, the local settings service creates them before applying volume.
- Mute All by muting the Master bus and local lobby music volume.
- Reduce Motion by toggling the Home/Lobby background motion flag.

Animation Speed, Confirm Big Bets, Show Hand Hints, and UI Scale are saved locally for current or future presentation systems to read. UI Scale is labeled in the panel as saved for a future UI scale pass.
