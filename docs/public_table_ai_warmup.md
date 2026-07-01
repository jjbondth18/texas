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

The returned public room shows only real players and moves to `ready_to_start` when at least two real connected players are seated. The host sees `START PUBLIC HAND`; non-host players see `Waiting for host to start.` The first version does not auto-start a formal public hand after warm-up interruption.

## Formal Public Hand Start

- `waiting_for_players`: fewer than two real connected seated players; host can start local AI warm-up.
- `ready_to_start`: at least two real connected seated players and no active formal hand; only the host can start the public hand.
- `playing`: a formal public hand is active; public seats are real players only.

The host starts the formal public hand through the server authoritative `start_hand` path. The server rejects non-host starts with `not_host`, rejects starts below two real players, and never includes warm-up AI in the official hand.

The dev-only `DEV: SIMULATE REAL PLAYER JOIN` button only validates the interruption path. The simulated seat is not AI and is not warm-up, but it is also not controlled by a real client. The server therefore rejects `START PUBLIC HAND` while that dev simulated player is seated:

`Dev simulated player cannot play a real public hand. Use a second client or enable DEV controllable bot.`

Use a second Godot client or a future controllable dev bot to test a real public hand.

## Mid-hand Real Join

If a real player joins while a public hand is active, the server seats that player as `waiting_next_hand`. The player is visible in the public room, but receives no current hand hole cards, does not post a blind in the current hand, and does not enter the current turn order. On the next host-started hand, `waiting_next_hand` players become eligible active players and receive cards normally.

## Exit and Wallet

Joining a public table moves the selected buy-in from wallet chips to the official server table stack. If the player exits before any formal public hand starts, the server refunds the full table stack with `left_before_official_hand`. Local warm-up is practice-only and never commits its chip result back to the account wallet.
