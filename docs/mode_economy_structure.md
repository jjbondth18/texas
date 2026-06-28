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
