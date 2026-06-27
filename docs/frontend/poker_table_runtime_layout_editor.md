# Poker Table Runtime Layout Editor

This developer-only tool lets you adjust the existing runtime Poker Table layout without rebuilding the scene hierarchy.

## Controls

- `F9`: toggle layout edit mode
- click a target: select
- drag: move selected target
- `Shift + drag`: resize selected target
- arrow keys: nudge selected target by 1 design pixel
- `Shift + arrow keys`: nudge by 10 design pixels
- `Ctrl + S`: save layout
- `Ctrl + R`: reset to captured default layout

## Save Location

Runtime saves to:

```text
user://poker_table_layout_config.json
```

The game never writes layout edits to `res://` at runtime.

## Committing A Layout Later

If you like a saved layout, manually copy the JSON from Godot's user data folder into:

```text
docs/frontend/poker_table_layout_config.default.json
```

This task does not automatically promote user layout edits into repository defaults.

## Editable Targets

The current mapping attempts to register:

```text
seat_1
seat_2
seat_3
seat_4
seat_5_local
seat_6
seat_7
seat_8
seat_9
left_info_panel
right_status_panel
local_player_info_panel
local_hole_cards
action_bar
community_board
pot_display
dealer_indicator
turn_timer
```

Missing targets are logged and ignored.

## Safety

Opening the table with no saved user config should look unchanged. The editor captures the current runtime rects as defaults after the normal UI is built and positioned, then applies `user://poker_table_layout_config.json` only if it exists.
