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
- `status = "waiting" | "playing" | "full"`
- `allow_quick_join = true`
- `buy_in`, `blinds`, `hand_count`, `max_players`, and `current_players`

Quick join uses a simple mock rule: prefer waiting, quick-joinable, non-full public chip tables with the most current players; otherwise join any non-full quick-joinable public chip table; otherwise create a default public chip table.

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
