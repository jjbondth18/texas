# Public Table AI Warm-up

Public Chip tables are real-player public tables. When fewer than two real players are seated, the table stays in `waiting_for_players` and does not start a formal public hand.

## Browser Create

- Creates a clean `public_chip` table.
- Seats the creator as a real player.
- Leaves the table in `waiting_for_players`.
- Does not spawn AI automatically.
- The poker table can show `START AI WARM-UP` so the creator can practice while waiting.

## AI Warm-up

- Sets `is_ai_warmup = true`.
- Adds temporary `warmup_ai` seats.
- Uses warm-up/practice play only.
- Does not change account chips, gems, ranked stats, public profit, leaderboard progress, or formal public hand results.
- Warm-up AI is not counted in `current_players`; the public list shows only real seated players.

## Quick No-match Flow

Quick Chip first tries to join a clean waiting/open public chip table. If none exists, it creates a clean public table, seats the local player, and starts AI warm-up automatically so the player can begin practicing immediately.

## Real Players Joining Warm-up

Real players may join an `ai_warmup` table from the Table Browser. They are added to `pending_real_joiners` and are not inserted into the current hand. Before the next hand starts, warm-up AI is removed, pending real players are seated, and the table either enters formal public play with at least two real players or returns to `waiting_for_players`.
