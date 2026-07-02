# Quick Play Public Table Matching

Quick Play is not a separate poker mode. It is an automatic matching layer over the same public chip table list used by the Browser.

## Flow

When the player presses `FIND TABLE` in Quick Chip:

1. Read the selected `buy_in`, `small_blind`, `big_blind`, and `hand_count`.
2. Search the public chip table list for a matching joinable table.
3. Join the best matching table if one exists.
4. If no matching table exists, create a new public chip table with the selected config.

Quick-created tables appear in the Browser list. Browser-created public chip tables can also be matched by Quick.

## Exact Match Rules

The first version uses strict config matching:

- `table_type = public_chip`
- `currency = chips` / local mock `chip`
- same `buy_in`
- same `small_blind`
- same `big_blind`
- same `hand_count`
- not full
- public, not private
- not training
- not a local-only warm-up table
- host local warm-up public rooms remain joinable
- not closed
- not `session_complete`

Unlimited only matches Unlimited.

## Joinable States

Quick only joins waiting public tables:

- `waiting_for_players`
- `waiting_ready`
- `ready_to_start`

If a host has started local AI warm-up, the real server public room still remains in `waiting_for_players` / `waiting_ready` with `host_in_local_warmup=true`. Quick may match that room when the selected stakes and hand count match. Joining it interrupts the host's local practice and returns both real clients to the public room.

Quick does not join `playing`, `hand_result`, `session_complete`, `closed`, or `paused` tables in this first version. Browser can later expose an explicit Join Next Hand flow for playing tables.

## Priority

When more than one table matches:

1. Prefer the table with the most real connected seated players.
2. If tied, prefer the earliest `created_at`.
3. If still tied, sort by `room_id` / `table_id`.

The choice is deterministic and never random.

## No Match

If no table matches, Quick creates a public chip table with the selected config. The player then enters the normal public waiting/ready flow:

- seated at the objective public seat
- `ready = false`
- no automatic deal
- no automatic warm-up
- `READY` and `START AI WARM-UP` are available after seat confirmation

## Gem Match

Quick Gem Match remains reserved for future secure matchmaking. It shows Coming Soon, does not create a table, does not deduct gems, and does not enter the poker table.
