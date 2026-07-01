# AI Practice Wallet Policy

AI Warm-up and Training are practice modes.

They must not change the authoritative account wallet:

- no wallet chip deduction for starting an AI practice hand
- no gem deduction
- no account wallet profit from wins
- no account wallet loss from losses
- no formal cash-game result or profit statistic from practice hands

AI Warm-up can reuse the current table stack for display and hand flow, but any warm-up result is ignored for account settlement. The server restores the real player's warm-up table stack baseline before the chips can be cashed out.

Training mode remains a local practice flow unless a future server training mode is added. If it becomes server-authoritative later, it should follow the same practice-chip rule.

For authoritative public tables, the selected buy-in is debited when the player sits in the real server room. That stack is still refundable before the first formal public hand starts. Exiting during `waiting_for_players`, local warm-up, or `ready_to_start` refunds the official stack to the wallet with reason `left_before_official_hand`; warm-up wins or losses are ignored.

Once a formal public hand starts, the table stack becomes part of the official hand economy and the existing public table cash-out rules apply after the hand is movable again.
