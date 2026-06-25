# Home Navigation Frontend Handoff V1

This handoff covers only Home Lobby navigation and PLAY mode cards.

## Main Navigation

Render `LobbyViewModel.main_nav` in order:

- `HOME` -> `home`
- `PLAY` -> `play`
- `REPLAY` -> `replay`
- `STORE` -> `store`
- `PROFILE` -> `profile`
- `SETTINGS` -> `settings`

`club` and generic `tournaments` are no longer Home Lobby main nav items.

## PLAY Mode Cards

Render `LobbyViewModel.modes` in order:

- `QUICK PLAY` -> `quick_play`
- `ROOM BROWSER` -> `room_browser`
- `PRIVATE TABLE` -> `private_table`
- `TRAINING` -> `training`
- `EVENTS` -> `events`

Use `id`, `title`, `subtitle`, `route`, and `enabled` from the ViewModel. Do not hardcode these labels in frontend scenes.

## Frontend Boundary

Frontend may consume these contracts, but this task does not require scene, visual script, asset, shader, screenshot, theme, or `project.godot` changes.
