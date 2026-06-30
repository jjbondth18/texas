# Public Table AI Warm-up

Public Chip tables are real-player public tables. When fewer than two real players are seated, the table stays in `waiting_for_players` and does not start a formal public hand.

## Browser Create

- Creates a clean `public_chip` table.
- Seats the creator as a real player.
- The creator is visible on the Poker Table while the table is waiting.
- The creator's table stack starts at the selected buy-in.
- Leaves the table in `waiting_for_players`.
- Does not spawn AI automatically.
- The poker table shows `START AI WARM-UP` only when the creator is seated, exactly one real player is present, the table is still waiting, and AI warm-up has not started.

## AI Warm-up

- AI Warm-up is a separate local practice table on the host client.
- The server public room remains real-player-only and stays open in `waiting_for_players`.
- The compatibility `start_ai_warmup` command only marks `host_in_local_warmup=true`; it does not start a server hand.
- AI never enters server public seats, never occupies public room capacity, and never appears in public table snapshots.
- Local warm-up uses practice chips only.
- Local warm-up does not change account chips, gems, ranked stats, public profit, leaderboard progress, or formal public hand results.
- The warm-up UI must show `LOCAL AI WARM-UP`, `Practice chips only`, and that the public room is waiting in the background.

## Quick No-match Flow

Quick Chip first tries to join a clean waiting/open public chip table. If none exists, it creates a clean public table and seats the local player. Local AI warm-up can then be started from the poker table while the public room waits for real players.

## Real Players Joining Warm-up

Real players join the real server public room, not the host's local warm-up table. When another real player sits in the public room, the host client must interrupt local warm-up immediately, clear local AI timers/seats/cards/pot, apply the latest server room snapshot, and return to the public table ready/waiting-to-start state.

The returned public room shows only real players. The host can then start a formal public hand through the server authoritative `start_hand` path.
