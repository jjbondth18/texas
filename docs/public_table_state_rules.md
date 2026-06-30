# Public Table State Rules

Public chip tables must be clean and joinable before Quick Chip or Table Browser can seat a player.

## Standard Public Chip Config

Quick Chip and Table Browser Create both normalize public table setup into these fields:

- `table_type = "public_chip"`
- `currency = "chip"`
- `buy_in`
- `small_blind`
- `big_blind`
- `hand_count`
- `max_players`
- `allow_quick_join`

Display-only blind labels such as `50 / 100` can exist in UI, but backend logic uses `small_blind` and `big_blind`.

## Clean Joinable Tables

Table Browser only lists clean joinable public chip tables:

- `table_type = public_chip`
- `currency = chip`
- `status` / `hand_state` is `waiting`, `open`, `idle`, or `pre_hand`
- not full
- not private room
- not training table
- not `hand_over`, `showdown_reveal`, `closed`, `paused`, `dirty`, or `finished`
- not a disconnected-only playing table

If a table is already `hand_over` with `current_turn_seat = -1`, it is treated as unavailable and removed from local mock listing when possible.

## Player Counting

Browser player counts only include connected seated players:

- not `empty`
- not `left`
- not `out`
- not `disconnected`
- `connected != false`
- `disconnected != true`

Disconnected bots do not count as current players and are not reused as active opponents. Local mock tables may generate fresh connected AI seats after a clean join, but stale disconnected bot residue is ignored.

## Quick Join

Quick Chip uses the selected stakes as preferences:

- first tries clean waiting/open public chip tables matching the selected config
- skips dirty, full, private, training, hand-over, and disconnected-only tables
- if no valid match exists, creates a new clean public chip table

New local mock public tables start with:

- `hand_state = waiting`
- `status = waiting`
- `pot = 0`
- `side_pots = []`
- `community_cards = []`
- `current_turn_seat = -1`
- no table log
- no players/seats/disconnected bot residue

## Browser Join

Table Browser validates a table before entering the launch transition and again before wallet buy-in is deducted. If the table is stale or unavailable, the player sees:

`This table is no longer available.`

Joining `hand_over`, `closed`, `dirty`, or disconnected-only tables is blocked.
