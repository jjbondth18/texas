# Replay Record Architecture

Replay phase 1 records completed hands and saves local JSON files. Replay Viewer v1 adds a static local hand review for those files. Replay playback is gated by a local gem unlock, but replay records are still always saved and never affect hand settlement.

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
- `dealer_id`
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

`dealer_id` is presentation metadata only. It identifies the dealer/croupier art used by the original table and is not part of poker rules, settlement, wallet changes, or replay unlock state.

## Mode Coverage

Authoritative public and private hands can carry a `replay_record` payload in the `table_snapshot` when the hand reaches `hand_over`. This server-built payload includes all seat hole cards at hand end and the full current-hand action log.

Training and local warm-up are recorded from the local `TexasTableFlow` snapshot when the local hand result is recorded. These are marked as practice modes and must not update account wallet, gems, or official stats.

## Replay Room

The Replay Room currently reads only `replay_index.json`. If no records exist, it shows:

`No hands recorded yet. Play a table to generate replay records.`

Replay index entries include `dealer_id` so the Replay Room can render dealer thumbnails without loading every full replay file. Old records or missing dealers fall back to the default dealer id, then to a neutral placeholder if the texture cannot load.

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

Viewer v1 does not do playback animation, equity charts, cloud loading, store integration, or real-money payment. Full replay playback is unlocked per replay through the local gem flow described below.

## Replay Viewer v1 Display Rules

Replay list rows are formatted for reading, not debugging:

- title: `Hand #000005`
- stakes line: `Public Table - NLH 50 / 100`
- result line: `Winner: Luna0581 - Pot 1,000`
- timestamp line: the `ended_at` / index timestamp when available
- right-side result: `+200 Chips`, `-100 Chips`, or `Practice`
- left thumbnail: dealer/croupier art from `dealer_id`

The detail page does not keep an empty top summary grid. The static review focuses on `PLAYERS`, `BOARD & RESULT`, and `ACTION TIMELINE`, with unlock/play actions beside the hand title.

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

Replay Detail does not show an empty equity placeholder. The real equity table lives inside ReplayPokerTableScreen after playback opens.

## Replay Unlock & Gems

Replay records are always saved locally, regardless of unlock state. Unlocking controls playback access only; it never changes the replay JSON file or the original hand result.

Current local-dev rules:

- unlock cost: `20` gems per replay
- unlock key: `hand_id:room_id` when both are available, otherwise the stable hand id or file path fallback
- unlock state is stored in the local player profile as `unlocked_replay_ids`
- replay unlocks are permanent for that local save profile
- repeated playback of an unlocked replay does not charge gems again
- if the player has fewer than 20 gems, the UI shows `Not enough gems. Visit Store to get more gems.`

Gem spending happens only in the Replay Detail unlock step through the profile/save service. `ReplayPokerTableScreen` never charges gems, never writes wallet data, never connects to the server, and never mutates replay records. Future cloud/server replay validation can replace the local unlock state later.

## Replay Playback v2

Replay Playback v2 adds a read-only step viewer launched from the Replay Detail panel with `PLAY REPLAY` after the selected replay has been unlocked. It stays inside the Replay Room UI and does not enter `PokerTableScreen`, connect to the authoritative server, send player actions, mutate wallet balances, write table transactions, or affect stats.

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

Future phases may add animated table replay and richer objective or player-view equity graphs. The local 20-gem unlock is now handled before playback opens.

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

Real table controls such as fold, check, call, raise, bet, add chips, ready, warm-up, cash-out, dealer changes, server connection, and player actions must not appear or run in Replay Table View. The renderer reuses the v2 playback state builder and does not re-run poker rules.

Replay Table View v3 intentionally does not include animated dealing, chip movement, equity graphs, cloud loading, or real-money access. The local 20-gem unlock is handled before playback opens, not inside the table view.

## Replay Table View v4 Display Contract

Replay Table View v4 keeps the v3 read-only renderer but makes the playback surface visually closer to the official poker table. It may reuse poker table visual assets and layout constants, but it must not reuse live session control paths.

The v4 renderer uses:

- `assets/poker_table/backgrounds/table_neon_v1.png` as the replay table background
- the official seat design coordinates scaled into the Replay panel
- the official bet marker design coordinates scaled into the Replay panel
- `CardView` for board cards and visible player hole cards
- chip stack and avatar ring assets from the neon poker UI kit
- official-style pot and bet marker panels

The renderer remains objective: seats are positioned by recorded `seat_index`, with no local-player camera rotation. Folded seats dim, the current actor seat highlights, and final winner seats receive a winner highlight at the last step.

Replay Table View v4 is still isolated from:

- server connections
- `player_action`
- live `PokerTableScreen` state
- wallet or gem mutation
- store purchases
- ready / warm-up / cash-out controls
- live betting, dealing, settlement, or hand progression logic

Future replay phases may add replay-specific card movement, chip movement, street transition animations, equity charts, and an explicitly designed gem unlock. Those remain out of scope for v4.

## Replay Table View v5 Fullscreen Layout

Replay Table View v5 moves playback out of the Replay Room detail panel and into a full-screen read-only overlay. Clicking `PLAY REPLAY` hides the Replay Room panel, list, detail content, large lobby branding, and prompt text while the overlay is active.

The fullscreen overlay uses:

- full-window `table_neon_v1.png` table background
- a compact top replay header with hand id, mode, blinds, step count, and current action
- objective replay seats scaled from the poker table visual contract
- board, pot, player cards, stacks, statuses, current actor highlight, folded dimming, and winner highlight from recorded playback state
- a narrow right-side timeline panel that can be hidden with `HIDE TIMELINE` / `SHOW TIMELINE`
- bottom-centered read-only playback controls: `PREV`, `PLAY` / `PAUSE`, `NEXT`, and `SPEED`
- top-right navigation: `BACK TO DETAIL`

`BACK TO DETAIL` hides the overlay and restores the selected replay detail. The replay list remains visible in the detail view, so fullscreen playback does not need a separate `BACK TO REPLAYS` button.

The fullscreen table view still only renders saved replay state. It does not connect to the server, send player actions, run live poker rules, mutate wallet or gems, cash out, enter store flows, or touch live `PokerTableScreen` session logic.

## ReplayPokerTableScreen Copy-From-Table Approach

ReplayPokerTableScreen replaces the hand-built fullscreen replay table surface with a replay-only copy of the official poker table visual structure. `PLAY REPLAY` now opens `scenes/screens/replay_poker_table_screen.tscn`, which is copied from the official table scene for visual parity but uses `scripts/screens/replay_poker_table_screen.gd` instead of the live `PokerTableScreen` script.

The replay screen intentionally reuses official visual components:

- `table_neon_v1.png` full table background
- official `PokerSeat` / `SeatPlayerCard` instances and seat anchors
- official `CommunityBoard` for board cards
- official `PotDisplay` for total pot
- official `TableStatusPanel` for left-side player status
- official `TableInfoPanel` log area repurposed as replay timeline
- official `ActionBar` bottom HUD styling, with its real action controls hidden and replaced by replay controls

ReplayPokerTableScreen is a read-only renderer. Its only data source is the replay playback state built by the existing replay state functions in `HomeLobbyScreen`: players, hole cards, board cards, pot, current bets, current actor, folded status, winners, and timeline steps. It does not connect to the server, does not send `player_action`, does not mutate wallet or gems, does not cash out, does not run ready or warm-up flows, and does not execute live betting/dealing/settlement logic.

The official table remains isolated. The live `PokerTableScreen` scene and script are not used for replay execution, and future replay changes should continue to happen in the replay screen/adapter unless a change is purely shared visual component work. Future phases may remove extra copied UI, add replay-specific animations, and add an equity timeline.

## Replay Equity Table

ReplayPokerTableScreen uses a compact equity table instead of an equity curve. The table is replay-only and lives in the bottom-left HUD slot, replacing the live player profile card while preserving the middle `YOUR HAND` panel and right-side `REPLAY CONTROLS`.

The table columns are:

- `Seat`
- `Player`
- `Preflop`
- `Flop`
- `Turn`
- `River`
- `Final`

Rows include only players recorded in the replay, sorted by objective `seat_index` and capped at nine players. The table keeps the header visible and places player rows inside an internal scroll area so nine-player hands do not expand the bottom HUD or overlap `YOUR HAND` / `REPLAY CONTROLS`. Missing streets display `-`; insufficient card data displays `N/A`; folded players remain listed and show `Folded` after they leave active equity calculation. `Final` displays `Win`, `Loss`, `Folded`, `Split`, or `-` depending on replay results.

The active replay step highlights the matching phase column: preflop, flop, turn, river, or final for showdown/hand-over steps. Equity values are produced by a replay-only deterministic Monte Carlo helper using recorded hole cards, board cards, and final results where available. The fixed seed makes the same replay render consistently.

The table supports two display modes:

- `Objective`: an all-seeing replay view that knows every recorded player's hole cards. Active player equities share the pot probability and folded players leave active calculations after their fold street.
- `Perceived`: each recorded player gets a separate player-view estimate. Each row knows only that player's own hole cards and the board cards visible on that street; all other active players are treated as unknown ranges. Perceived rows are independent information sets, so values in the same street column do not need to add up to 100%. There is no `Opponents combined` row.

Both modes currently use deterministic Monte Carlo rather than exact enumeration. Objective mode samples remaining board cards from the known deck after recorded hole cards and current board cards are removed. Perceived mode samples unknown opponent hole cards and remaining board cards independently for each player's information set. The fixed seed prevents UI jitter between renders of the same replay.

This table does not connect to the server, does not mutate wallet or gems, does not change replay records, and does not touch live `PokerTableScreen` logic. Future phases may add richer charts, exact enumeration options, or click-to-focus player perspective controls.

## Replay Playback Performance Rules

Replay playback must keep the live table background and UI animation smooth while steps advance. Equity data is cached when the replay context is opened: Objective and Perceived tables are built once and reused for preflop, flop, turn, river, and final highlights. Step playback must not rerun Monte Carlo equity calculation.

Replay UI nodes should be built once and updated in place. Seat cards, bottom cards, table controls, timeline content, and equity table cells are reused during playback; step updates should only change text, visibility, card values, pot values, and highlight style. Timeline content is cached and sent to the log panel once, while current-step context is shown in the replay header and controls.

Replay panels should remain translucent. The Equity Table panel keeps its neon border but uses a semi-transparent dark fill so the table background remains visible behind it; individual cells also use translucent fills with a slightly brighter active-street highlight.

## Future Phases

Later replay work can add:

- a step-by-step playback screen
- street-by-street community card and action playback
- hand range and equity graphs
- optional cloud replay upload
- paid or gem-gated analysis, only after a separate economy design
