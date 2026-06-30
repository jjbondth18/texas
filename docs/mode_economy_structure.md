# Mode Economy Structure

## Training

Training is an AI practice mode.

- Uses practice chips only.
- Does not deduct account chips when the table starts.
- Does not add winnings back to account chips when the table ends.
- Does not change gems.
- Does not write ranked stats such as sessions played, hands played, hands won, total profit, best session profit, or biggest pot.
- Does not update leaderboards, achievements, missions, or ranked rewards.
- Does not grant Gem rewards.

Training table contexts must carry explicit economy flags:

- `mode = "training"`
- `table_type = "training_ai"`
- `uses_practice_chips = true`
- `affects_account_balance = false`

The table may still show the local training result for the current session, but that result is only a practice summary.

## Public Chip Table Registry

Public chip tables are the shared local/mock table directory for account-chip poker.

- Quick Chip = automatically joins a public chip table through `quick_join_public_table`.
- Table Browser = manually browses, creates, and joins public chip tables from the same registry.
- Friends Room = private room code flow; it uses `table_type = "private_room"` and is not listed.
- Training = AI practice mode; it uses `table_type = "training_ai"` and is not listed.
- Gem Match = reserved server-required mode; it remains Coming Soon and is not listed.

The current registry is local/mock only. A future server implementation can replace the registry while preserving the same table concepts:

- `table_type = "public_chip"`
- `currency = "chip"`
- joinable `status` / `hand_state = "waiting" | "open" | "idle" | "pre_hand"`
- `allow_quick_join = true`
- `buy_in`, `small_blind`, `big_blind`, `hand_count`, `max_players`, and `current_players`

Quick join uses a simple mock rule: prefer clean waiting/open, quick-joinable, non-full public chip tables matching the selected config; otherwise create a new clean public chip table. Hand-over, closed, dirty, private, training, and disconnected-only tables are not joinable.

## Table Launch Flow

All real table launches from the Home/Lobby UI pass through the same lightweight launch transition before the poker table scene opens.

- Quick Chip: Finding a public chip table.
- Table Browser Join: Joining a public table.
- Table Browser Create: Creating a public table.
- Friends Room Start: Creating a private room table.
- Training: Preparing an AI training table.

The transition is presentation only. It does not change public table registry selection, practice-chip isolation, account chip/gem balances, session settlement, or table context data.

Gem Match remains a reserved server-required mode and does not enter the launch flow.

## Mode Entry Labels

- Quick Chip: auto-joins an available public chip table with account chips.
- Table Browser: manual public chip table list for browsing, creating, and joining public tables.
- Friends Room: private room code flow for invited friends; private rooms are not public tables.
- Training: AI practice mode using practice chips; results do not affect account balance or ranked stats.
- Gem Match: future secure server mode; currently reserved and unavailable.

## Quick vs Table Browser vs Friends Room

Quick Play is the fast path. It keeps lightweight stake selection while avoiding explicit manual room creation flow.

- Chip Table: treats the selected Buy-in, Blinds, and Hand Count as quick join preferences.
- Gem Match: reserved and unavailable until secure server matchmaking exists.

Quick Play exposes Buy-in, Blinds, and Hand Count in the setup panel. These are not manual room creation controls. They are preferences for `quick_join_public_table(config)`:

- First, quick join looks for a non-full, quick-joinable `public_chip` table matching the selected buy-in, blinds, and compatible hand count.
- If a matching public table exists, Quick joins that table.
- If no matching table exists, Quick automatically creates a public chip table using the selected config and joins it.
- The config passed to the registry/server uses `buy_in`, `small_blind`, `big_blind`, `hand_count`, `max_players`, `table_type = public_chip`, and `currency = chip`.
- Quick never joins `hand_over`, closed, dirty, private, training, or disconnected-only tables.

If the wallet cannot cover the selected public chip table buy-in, Quick Play shows "Not enough wallet chips" and does not enter a table.

Table Browser is the manual public chip table flow.

- Existing public tables can be joined directly.
- Only clean joinable public chip tables are shown.
- Joining an existing public table does not open the create setup panel.
- Creating a public table opens a `CREATE PUBLIC TABLE` setup panel first.
- Public table setup uses the same visual setup panel language as Quick Play and supports Buy-in, Blinds, and Hand Count.
- Created tables use `table_type = "public_chip"`.
- Public Gem tables are visible as a reserved option but disabled/Coming Soon because they require secure server matchmaking.
- Public chip tables do not support Gem buy-in in the current mock.
- Quick Chip auto-join can seat players into the same public chip table registry.
- Disconnected players or bots are not counted in Browser player totals.

## Public Table AI Warm-up

Public Chip tables remain real-player public tables. When fewer than two real players are seated, a table is `waiting_for_players` and does not start a formal public hand.

- Browser Create seats the creator and leaves the table waiting by default; no AI is spawned automatically.
- The poker table can show `START AI WARM-UP` while waiting.
- AI Warm-up sets `is_ai_warmup = true` and uses temporary `warmup_ai` seats.
- Warm-up hands use practice/warm-up chips only and do not write account chip/gem balances, ranked stats, public profit, leaderboard progress, or formal public results.
- Quick Chip can automatically start AI Warm-up only when no clean waiting/open public table exists.
- Warm-up AI does not count toward public `current_players`; Browser player counts are real players only.
- Real players joining an AI Warm-up table are stored in `pending_real_joiners` and are seated before the next hand, after warm-up AI is removed.
- If pending real players bring the table to at least two real players, the table can enter formal public play; otherwise it returns to `waiting_for_players`.

Friends Room is the private casual room flow.

- Private rooms are created with a room code.
- Creating a private room opens a `CREATE PRIVATE ROOM` setup panel first.
- Private room setup uses the same visual setup panel language as Quick Play and supports Starting Stack / Buy-in, Blinds, and Hand Count.
- Private rooms use `table_type = "private_room"` or `private_casual`.
- Private rooms are not listed in the public table registry and are not selected by Quick Chip.
- Private Gem is shown as a future private match option, but the current local mock does not deduct Gems, create Gem rooms, or perform real Gem settlement.

## Leave / Timeout / Sit Out Rules

These rules describe the local/mock table behavior and the target contract for the future server-authoritative table.

- If a player leaves or disconnects during a hand, chips already committed to the pot remain in the pot.
- The leaving player's current hand is folded and the player is not dealt into the next hand.
- The leaving player's uncommitted table stack is not gifted to other players.
- Public chip tables record the uncommitted stack as a pending cash out/refund for future authoritative settlement.
- Private casual rooms return the uncommitted stack to the local casual room state or simply clear the seat.
- Training discards the remaining practice stack and never writes it back to account chips or gems.
- If a player times out and checking is available, the local/mock action is auto-check.
- If a player times out and checking is not available, the local/mock action is auto-fold.
- After two consecutive timeouts, the player is marked `sit_out`.
- `sit_out` players do not post new blinds, do not receive new hole cards, and are not counted as active for the next hand.
- If active players fall below the table minimum, the table moves to `paused` or `waiting` until enough players are available.
- In the P2P/mock prototype, host leave closes the table safely and reports: "Host left. Table closed safely. Account balances were not changed."
- The host client is not trusted to finalize account settlement. In the future server version, the server maintains table state and the host has no special settlement authority.

Gem Match remains reserved and does not enter these table lifecycle rules because it does not create a table.
