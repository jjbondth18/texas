# Replay Record Architecture

This is replay phase 1. The game records completed hands and saves local JSON files, but it does not include a replay viewer, gem unlocks, payment, equity graphs, or cloud replay storage.

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

The step-by-step replay viewer and equity timeline are future phases. This phase does not charge gems or unlock paid analysis.

## Future Phases

Later replay work can add:

- a step-by-step playback screen
- street-by-street community card and action playback
- hand range and equity graphs
- optional cloud replay upload
- paid or gem-gated analysis, only after a separate economy design
