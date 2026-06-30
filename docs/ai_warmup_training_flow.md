# AI Warm-up and Training Flow

AI Warm-up and Training are practice flows.

AI Warm-up is available on a public chip table after the real player is seated and the table is waiting for more real players. The client sends `start_ai_warmup`; the authoritative server adds temporary `warmup_ai` seats and marks snapshots with `is_ai_warmup=true` and `table_state=ai_warmup`.

Training is a standalone local AI practice mode. It uses `table_type=training_ai`, `uses_practice_chips=true`, and `affects_account_balance=false`. It does not depend on the public table browser, public table registry, server room seating, or the normal two-real-player public start rule.

Both modes are practice only:

- no account wallet chip or gem gain
- no account wallet chip or gem loss from hand results
- no formal public cash-game result or profit statistic
- no ranked/profile progression from practice hands

Warm-up hand-over snapshots show the result briefly, then the server schedules the next warm-up hand. Before the next hand, public cards, pot, bets, folded/all-in state, and current turn are reset by the normal hand start flow. Real-player table stacks are restored to the warm-up baseline so practice wins or losses cannot be cashed out.

Training hand-over uses the local table flow result reveal and then starts the next training hand automatically when the session can continue.

Exit Table must be safe in waiting, seat confirmation, AI Warm-up, hand-over, showdown reveal, and Training. The client cancels pending local next-hand timers, sends a server cash-out/leave request when connected, waits only briefly for wallet sync, then returns home. Training exits locally and discards practice stacks without touching account wallet data.
