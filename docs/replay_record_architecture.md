# Replay Record Architecture

Replay phase 1 records completed hands and saves local JSON files. Replay Viewer v1 adds a static local hand review for those files. This replay stack still does not include animation playback, gem unlocks, payment, equity graphs, or cloud replay storage.

## Storage

Replay records are saved under:

`user://replays/`

The local index is saved at:

`user://replays/replay_index.json`

Record filenames are based on mode and hand identity, for example:

- `room_1_hand_000001.json`
- `private_A7K9_hand_000001.json`
- `training_hand_000001.json`
- `warmup_hand_000001.json`

If saving a replay fails, the table continues normally and only logs a warning. Replay persistence must never affect wallet, gems, settlement, pot awards, cash-out, buy-in, or next-hand timing.

## Record Schema

Each `HandReplayRecord` contains:

- `replay_version`
- `hand_id`
- `room_id`
- `room_code`
- `mode`: `public`, `private`, `training`, or `local_warmup`
- `table_type`
- `started_at`
- `ended_at`
- `small_blind`
- `big_blind`
- `button_seat`
- `small_blind_seat`
- `big_blind_seat`
- `max_hands`
- `hand_number`
- `players`
- `community_cards`
- `actions`
- `results`

Player records include `player_id`, `player_name`, `seat_index`, `avatar_id`, `is_ai`, `is_local_warmup_ai`, `starting_stack`, `ending_stack`, `hole_cards`, and `final_status`.

Action records include `seq`, `street`, `actor_seat`, `actor_player_id`, `action`, `amount`, `bet_to`, `pot_after`, `player_stack_after`, `timestamp_ms`, and `message`.

Result records include winners, winner seat/player identifiers, amount won, hand rank text where available, pot type, final pot, side pots, and server hand result rows where available.

## Mode Coverage

Authoritative public and private hands can carry a `replay_record` payload in the `table_snapshot` when the hand reaches `hand_over`. This server-built payload includes all seat hole cards at hand end and the full current-hand action log.

Training and local warm-up are recorded from the local `TexasTableFlow` snapshot when the local hand result is recorded. These are marked as practice modes and must not update account wallet, gems, or official stats.

## Replay Room

The Replay Room currently reads only `replay_index.json`. If no records exist, it shows:

`No hands recorded yet. Play a table to generate replay records.`

## Replay Viewer v1

Replay Viewer v1 is a static local hand review. Clicking a replay row in the Replay Room loads the row's `file_path` JSON from `user://replays/` and renders a detail panel in the lobby. It does not enter `PokerTableScreen`.

The static detail panel shows:

- hand id / hand number
- mode
- room id or room code
- blinds
- result / profit
- final pot
- winner summary
- players sorted by `seat_index`
- player hole cards when present
- starting and ending stacks
- board cards grouped as flop / turn / river
- actions sorted by `seq`
- winners and side pot count

Missing fields are tolerated. Missing hole cards display `Unknown`, missing winner/rank fields display `-`, and a missing JSON file displays `Replay file missing.` without crashing.

Viewer v1 does not do playback animation, equity charts, cloud loading, gem checks, gem spending, store integration, or paid unlocks.

## Replay Viewer v1 Display Rules

Replay list rows are formatted for reading, not debugging:

- title: `Hand #000005`
- stakes line: `Public Table - NLH 50 / 100`
- result line: `Winner: Luna0581 - Pot 1,000`
- timestamp line: the `ended_at` / index timestamp when available
- right-side result: `+200 Chips`, `-100 Chips`, or `Practice`

The detail top summary must show values beside every label:

- `MODE`: `Public Table`, `Private Room`, `Training`, `Local Warm-up`, or `Unknown`
- `ROOM`: `Room Code A7K9`, `room_2`, or `-`
- `BLINDS`: `50 / 100` or `-`
- `HAND`: `5 / 10`, `5 / Unlimited`, `hand_000005`, or `-`
- `RESULT`: `Win`, `Loss`, `Practice`, or `-`
- `PROFIT`: `+200 Chips`, `-100 Chips`, `Practice`, or `-`
- `FINAL POT`: formatted chip amount or `-`
- `WINNER`: player name resolved from `seat_index` when possible, otherwise seat/player id, or `-`

Players are sorted by `seat_index` and displayed as individual blocks:

- `Seat 5 - Luna0581`
- `Cards: KH 7S` or `Cards: Unknown`
- `Stack: 5,000 -> 5,500 (+500)`
- `Status: Winner`, `Folded`, `Showdown`, `Lost`, or `-`

Board and result display is grouped:

- `Flop`, `Turn`, and `River` are shown separately.
- If no board cards exist, show `No board cards recorded.`
- Winners display as `Seat 5 - Luna0581 wins 1,000` plus `Hand: One Pair` where available.
- If no result rows exist, show `No results recorded.`

Action timeline display is grouped by street (`PREFLOP`, `FLOP`, `TURN`, `RIVER`, `SHOWDOWN`) and uses viewer-local numbering from 1. Debug separator messages such as `---- Hand 1 ----` are filtered out instead of rendered. Action names are converted to readable phrases such as `posts small blind`, `checks`, `calls 50`, `raises to 300`, and `goes all-in 1,000`.

The equity timeline remains a compact placeholder: `Equity Timeline - Coming in a later update.` Viewer v1 must not show unlock prompts, charge gems, or imply premium replay access.

## Future Phases

Later replay work can add:

- a step-by-step playback screen
- street-by-street community card and action playback
- hand range and equity graphs
- optional cloud replay upload
- paid or gem-gated analysis, only after a separate economy design
