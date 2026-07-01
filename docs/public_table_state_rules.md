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

## Lifecycle

- `waiting_for_players`: fewer than two real connected seated players. The host can use local AI warm-up, but no server public hand starts.
- `ready_to_start`: at least two real connected seated players and no active hand. The host sees `START PUBLIC HAND`; non-host players wait for the host.
- `playing`: a formal public hand is active. New real players may join an open seat, but their seat status is `waiting_next_hand`.
- `hand_over`: settlement completed. The room returns to `ready_to_start` when at least two real connected players remain.

AI warm-up is always local practice. Warm-up AI never enters public seats and never joins official public hands.

The official account-wallet boundary is the first successful server public `start_hand`. A player who leaves a public table before that formal hand starts receives the full server table stack back to the wallet with reason `left_before_official_hand`. Local warm-up hands do not change wallet chips, gems, formal stats, or public profit.

The dev-only simulated real join button is only for testing warm-up interruption and `ready_to_start` UI. A dev simulated player is seated as a real-looking public seat, but it has no controller and the server rejects formal public `start_hand` while it is present. Use a second real client for an actual public hand test.

Formal public hands use a server action timeout. If a player does not act before the timeout, the server auto-checks when legal, otherwise auto-folds, logs the timeout, broadcasts a snapshot, and schedules the next turn.

The client displays the same action timer in the bottom action area, Player Status, and the table info timer bar. Bet markers are positioned by stable `seat_index` anchors, not by Player Status order or dynamic seat-card text.

## Clean Joinable Tables

Table Browser only lists clean joinable public chip tables:

- `table_type = public_chip`
- `currency = chip`
- `status` / `hand_state` is `waiting`, `waiting_for_players`, `ready_to_start`, `open`, `playing`, an active hand phase (`preflop`, `flop`, `turn`, `river`, `showdown`), `idle`, or `pre_hand`
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

## Mid-hand Join

When a public hand is already in progress, a new real player may join if a seat is open. The player is marked `waiting_next_hand`, gets no current hand hole cards, does not post a blind for the current hand, and does not affect the current pot or turn order. On the next hand, `waiting_next_hand` players become eligible to receive cards.

## Quick Join

Quick Chip uses the selected stakes as preferences:

- first tries clean waiting/open/ready public chip tables matching the selected config
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
