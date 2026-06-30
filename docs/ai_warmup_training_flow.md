# AI Warm-up and Training Flow

AI Warm-up and Training are practice flows.

AI Warm-up is available on a public chip table after the real player is seated and the table is waiting for more real players. In authoritative public tables, Warm-up is a separate local practice table on the host client. The client may send `start_ai_warmup` as a compatibility notification, but the server only records `host_in_local_warmup=true`; it does not add AI seats, start a server hand, or mark public snapshots as `is_ai_warmup=true`.

Training is a standalone local AI practice mode. It uses `table_type=training_ai`, `uses_practice_chips=true`, and `affects_account_balance=false`. It does not depend on the public table browser, public table registry, server room seating, or the normal two-real-player public start rule.

Both modes are practice only:

- no account wallet chip or gem gain
- no account wallet chip or gem loss from hand results
- no formal public cash-game result or profit statistic
- no ranked/profile progression from practice hands

Warm-up hand-over snapshots show the local practice result briefly, then the client can start the next local practice hand. Public room cards, pot, bets, folded/all-in state, and official table stacks are not touched by warm-up.

## Authoritative AI Warm-up Pacing

Authoritative AI Warm-up uses the same local AI pacing path as Training. AI actions are local practice actions, one at a time, and never server-authoritative public actions.

Human turns pause the local scheduler. When the current turn belongs to the real player, the client waits for local practice input and does not send public `player_action` messages to the server.

Warm-up exit, hand-over, next-hand start, and real-player join interrupts cancel pending local AI timers. This prevents old local timers from acting after the player leaves, after the hand is already over, after a new hand has started, or after the host returns to the public room.

Player Status rows are rendered in stable `seat_index` order during local public warm-up. Turn changes update the existing row highlight and status text only; rows are not reordered, recreated, or resized just because the active player changed.

When a real player joins the server public room, the host immediately stops local warm-up and returns to the latest server public room snapshot. The official public room remains real-player-only, and the formal hand starts only through the server authoritative public hand path.

Training hand-over uses the local table flow result reveal and then starts the next training hand automatically when the session can continue.

Exit Table must be safe in waiting, seat confirmation, AI Warm-up, hand-over, showdown reveal, and Training. The client cancels pending local next-hand timers, sends a server cash-out/leave request when connected, waits only briefly for wallet sync, then returns home. Training exits locally and discards practice stacks without touching account wallet data.
