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

## Replay Playback v2

Replay Playback v2 adds a read-only step viewer launched from the Replay Detail panel with `PLAY REPLAY`. It stays inside the Replay Room UI and does not enter `PokerTableScreen`, connect to the authoritative server, send player actions, mutate wallet balances, spend gems, write table transactions, or affect stats.

When playback opens, the Replay list collapses so the review area can use the full panel width. This is intentional: playback should feel like a hand review table, not a narrow lobby detail card.

Playback initializes from the saved `HandReplayRecord`:

- players are sorted by `seat_index`
- every player starts at `starting_stack`
- all recorded hole cards are visible because this is an objective hand review
- pot starts at `0`
- board starts empty
- current step starts at `0`

The controls are read-only:

- `BACK TO DETAIL`
- `BACK TO REPLAYS`
- `PREV`
- `NEXT`
- `PLAY` / `PAUSE`
- optional `SPEED 1x` / `SPEED 2x`

Real table controls such as fold, check, call, bet, raise, add chips, ready, warm-up, store, dealer changes, and cash-out must never appear in playback mode.

Playback applies recorded actions in `seq` order. `NEXT` applies one more action. `PREV` rebuilds state from the initial replay state up to the target step instead of trying to reverse individual poker operations. `PLAY` advances every `0.8` seconds at 1x speed and pauses automatically at the final step.

The step list is not limited to raw player actions. Playback expands the record into:

- player actions such as blinds, checks, calls, bets, raises, folds, all-ins, and timeout auto-actions
- hand events such as hand start, flop/turn/river reveal, showdown, and hand settled
- non-player system messages from the record, displayed separately from player actions

The timeline visually separates `PLAYER ACTIONS` from `HAND EVENTS` so lines such as `Hand 10 started`, `settled`, or stack summaries do not read like betting decisions.

Playback does not re-run poker rules. It prioritizes recorded state fields:

- `pot_after` updates pot when present
- `player_stack_after` updates the acting player's stack when present
- `bet_to` updates the acting player's current bet when present

When those fields are missing, playback uses simple display-only fallback updates so the review remains readable. It does not recalculate side pots or re-settle the hand.

Board reveal is based on the current action street:

- `preflop`: no board cards
- `flop`: flop cards
- `turn`: flop + turn
- `river`, `showdown`, `hand_over`, or final step: full board

Malformed or incomplete records must degrade gracefully:

- missing players: `No players recorded.`
- missing actions: `No actions recorded.`
- missing board: `No board cards recorded.`
- missing results: `No results recorded.`
- missing hole cards: `Unknown`
- missing stacks: `-`

Future phases may add a 20-gem unlock, animated table replay, and objective or player-view equity graphs. Those are intentionally out of scope for v2.

## Replay Table View v3

Replay Table View v3 upgrades playback from a text-heavy review panel into a read-only poker-table renderer. It is still launched from `PLAY REPLAY`, still lives inside the Replay Room, and still does not enter or reuse live `PokerTableScreen` session logic.

The table view renders the existing playback state:

- objective `seat_index` positions for all recorded players
- player names, seats, hole cards, current stack, current bet, and status
- folded players with dimmed seat cards
- the current actor with a highlighted seat card
- final winners with a winner highlight at the last step
- board cards revealed by street
- total pot from recorded `pot_after` / display fallback state
- current step text
- separated `PLAYER ACTIONS` and `HAND EVENTS` timeline sections

The controls remain read-only:

- `BACK TO DETAIL`
- `PREV`
- `NEXT`
- `PLAY` / `PAUSE`
- `SPEED 1x` / `SPEED 2x`
- `BACK TO REPLAYS`

Real table controls such as fold, check, call, raise, bet, add chips, ready, warm-up, cash-out, dealer changes, server connection, and player actions must not appear or run in Replay Table View. The renderer reuses the v2 playback state builder and does not re-run poker rules.

Replay Table View v3 intentionally does not include animated dealing, chip movement, equity graphs, gem unlocks, cloud loading, or paid replay access. Future phases may add replay-specific animations, an equity timeline, and a separately designed 20-gem unlock.

## Future Phases

Later replay work can add:

- a step-by-step playback screen
- street-by-street community card and action playback
- hand range and equity graphs
- optional cloud replay upload
- paid or gem-gated analysis, only after a separate economy design
