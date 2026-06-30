# Authoritative Table Snapshot Contract

The server authoritative table is the source of truth for public table seats. The Godot client must not infer seated players from the bottom profile panel or local mock state.

## Public Browser Create Flow

When a player creates a public chip table from the browser:

1. The server creates the public room/table.
2. The Godot poker table joins the room.
3. The Godot poker table sends `sit_down` for the local player.
4. The server must write the player into `seats[0]` or the requested seat.
5. The next `table_snapshot` must include the occupied seat before the table is considered valid.

If `sit_down` fails, the client should show a server error instead of treating an empty table as a valid waiting table.

## Seat Fields

Each public seat in `table_snapshot.seats` should include:

- `seat_index`
- `occupied`
- `player_id`
- `player_name` / `name`
- `avatar_id`
- `connected`
- `is_ai`
- `status`
- `chips`
- `table_stack`
- `current_bet`
- `folded`

Empty seats should use `occupied=false` and `status=empty`.

## Waiting State Rendering

Godot must render occupied seats even while the table is still in `waiting` / `waiting_for_players`.

The waiting state is also used to decide whether to show `START AI WARM-UP`. The button is visible when:

- table type is `public_chip`
- server phase is waiting
- local player is seated
- one connected real player is seated
- no AI warm-up is active
- no hand is active

## Browser List Count

The public table list should count connected real seated players. Empty seats, disconnected seats, and warm-up AI seats do not count toward `current_players`.
