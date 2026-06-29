# Settings Structure

Settings are local player preferences for the Home/Lobby and presentation layer.

- Settings do not change wallet chips, gems, store purchases, daily bonus, avatars, or ranked profile stats.
- Settings do not change poker rules, dealing, betting, settlement, table registry behavior, or mode economy.
- Settings do not enable a real server, cloud sync, account binding, or Gem Match.
- Cloud Sync, Account Binding, and Future Server are visible placeholders only.

## Stored Fields

- `master_volume`, `music_volume`, `sfx_volume`, and `mute_all` are safe audio preferences.
- `show_hand_hints`, `auto_muck_losing_hands`, and `confirm_big_bets` are gameplay UI preferences for future table reads.
- `animation_speed` and `reduce_motion` are local animation preferences for future UI and table animation systems.
- `window_mode` and `ui_scale` are saved locally; current UI treats them as apply-on-restart/future-read fields.
- `show_player_name` and `allow_friend_invites` are local privacy preferences.
- `server_region` and `network_mode` are advanced placeholders. `network_mode = "future_server"` is Coming Soon and must not switch backend behavior.

## Applied Now

The current implementation safely applies:

- Master/Music/SFX bus volume when matching AudioServer buses exist.
- Mute All by muting the Master bus and local lobby music volume.
- Reduce Motion by toggling the Home/Lobby background motion flag.

All other fields are saved locally for future systems to read.
