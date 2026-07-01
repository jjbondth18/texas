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

- `waiting_for_players` / `waiting_ready`: no active hand. Public Create seats the creator at objective seat `5`, and additional real players use the objective join order `[5, 8, 2, 6, 4, 9, 1, 7, 3]`.
- `waiting_ready`: the Ready system is available only after the client has a confirmed seated snapshot. Players may press `READY` / `UNREADY`; at least two ready real players are required before a formal public hand can start.
- `starting_countdown`: all required real players are ready. The server starts a 3 second countdown and then automatically starts the formal public hand.
- `playing`: a formal public hand is active. New real players may join an open seat, but their seat status is `waiting_next_hand`.
- `hand_result` / `hand_over`: settlement completed. After the first formal public hand starts, later hands continue automatically after the result display if at least two ready real candidates remain.
- `session_complete`: the selected hand count has been reached. The server cancels ready/action/next-hand timers, stops dealing, broadcasts a final snapshot, and rejects further player actions until the session is reset or the player exits.

AI warm-up is always local practice. Warm-up AI never enters public seats and never joins official public hands.

Ready does not replace `sit_down`: clients must wait for `sit_down_result` or a `table_snapshot` with their own occupied seat before showing Ready controls. If `local_player_seat_index == -1`, the table shows a joining / waiting-for-seat state instead of a valid ready table.

With one seated real player, the table still shows local `START AI WARM-UP` for practice. This warm-up does not use server seats and does not change wallet, gems, formal stats, or public profit.

The official account-wallet boundary is the first successful server public `start_hand`. A player who leaves a public table before that formal hand starts receives the full server table stack back to the wallet with reason `left_before_official_hand`. Local warm-up hands do not change wallet chips, gems, formal stats, or public profit.

## Hand Count Limit

Public tables honor the selected hand count as a hard limit: `5`, `10`, `20`, or `Unlimited`.

The server snapshot exposes:

- `max_hands`
- `hands_played`
- `current_hand_number`
- `session_complete`

For a 10-hand table, the first hand is `current_hand_number = 1`, and after the tenth result display finishes the room enters `session_complete`. The server must not create hand 11 through any auto-next-hand, ready countdown, manual start, bot, or debug path.

Unlimited tables use `max_hands = 0` and the UI displays `Hand N / Unlimited`.

## Session Complete

At `session_complete`, the client shows the Session Complete panel with final stacks and two actions:

- `PLAY AGAIN`: resets the same room session counter, clears board/cards/bets/pot, keeps seated players and current table stacks, sets all players `ready=false`, and returns to `waiting_ready`. It does not deduct a new buy-in.
- `EXIT TABLE`: leaves the table, cashes out the player's current table stack to the authoritative server wallet, cancels pending timers, and returns home/browser.

If the final hand ends in showdown, the hand result remains visible for the normal result delay before the Session Complete panel appears.

`EXIT TABLE` always opens a confirmation dialog. The client sends server `cash_out` and waits for a wallet snapshot before returning home. If the server errors or settlement times out, the player stays on the table and the error is shown instead of silently dropping the buy-in.

When a player exits during a formal hand, the server folds that player, leaves committed chips in the pot, cashes out only the remaining table stack, and clears the seat after the hand can be settled safely.

The dev-only simulated real join button is only for testing warm-up interruption and Ready UI. A dev simulated player is seated as a real-looking public seat, but it has no controller and the server rejects formal public hand start while it is present. Use a second real client for an actual public hand test.

Formal public hands use a server action timeout. If a player does not act before the timeout, the server auto-checks when legal, otherwise auto-folds, logs the timeout, broadcasts a snapshot, and schedules the next turn.

The client displays the same action timer in the bottom action area, Player Status, and the table info timer bar. Bet markers are positioned by stable `seat_index` anchors, not by Player Status order or dynamic seat-card text.

## Clean Joinable Tables

Table Browser only lists clean joinable public chip tables:

- `table_type = public_chip`
- `currency = chip`
- `status` / `hand_state` is `waiting`, `waiting_for_players`, `waiting_ready`, `starting_countdown`, `hand_result`, `open`, `playing`, an active hand phase (`preflop`, `flop`, `turn`, `river`, `showdown`), `idle`, or `pre_hand`
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
