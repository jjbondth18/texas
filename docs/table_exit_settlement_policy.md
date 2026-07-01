# Table Exit Settlement Policy

This project treats server-authoritative public table chips as separate from the account wallet.

## Buy-In

When a player successfully sits at a server table, the server deducts the room buy-in from the wallet and writes a wallet transaction:

- reason: `table_buy_in`
- amount: `-buy_in`

The client must wait for `sit_down_result` or a confirmed `table_snapshot` before treating the player as seated.

## Exit Before Official Public Hand

If a player leaves a public table before the first official server hand starts, the full current table stack is returned to the wallet.

- reason: `left_before_official_hand`
- amount: remaining table stack

Local AI warm-up is practice only. Warm-up results never change wallet chips or gems.

## Exit Between Hands

After an official session has started, leaving while no hand is active cashes out the player's current table stack.

- reason: `table_cash_out`
- amount: remaining table stack

At `session_complete`, the same table-stack return uses:

- reason: `session_complete_cash_out`

## Exit During an Active Hand

If a player exits while a formal hand is active, the server auto-folds that seat. Chips already committed to the pot remain committed. Only the uncommitted remaining table stack is returned to the wallet.

- reason: `table_cash_out`
- amount: remaining uncommitted table stack

The seat is kept only as long as required to preserve pot contribution and hand settlement, then cleared.

## Double Settlement Protection

The server tracks settled player exits by room and player. Repeated `cash_out` / `leave_seat` messages for the same room do not return chips twice.

The wallet repository exposes an audit helper that can detect `table_buy_in` transactions without a matching refund or cash-out reason.

## Client Exit UX

`Exit Table` must show a confirmation dialog before sending settlement:

- before official hand: full table stack returned
- local warm-up: practice only, wallet unaffected by warm-up
- between hands: current table stack cashed out
- during a hand: auto-fold, committed pot chips stay, remaining stack cashed out

The client returns home only after a server wallet snapshot confirms settlement. If settlement times out or the server returns an error, the client stays on the table and shows the error.
