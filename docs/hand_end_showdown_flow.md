# Hand End Showdown Flow

This project now keeps a short hand-end presentation phase before the next hand starts.

Formal play never requires the player to press `S` to continue. Debug/manual start shortcuts are only available when dev debug tools are explicitly enabled, and the normal UI should say that the next hand is starting automatically.

## Showdown

When a hand ends with two or more showdown-eligible players still in the hand, the table enters a showdown reveal presentation:

- Active/showdown-eligible players reveal their hole cards.
- Folded players remain hidden.
- The result banner shows the winner or split winners, the pot amount, and the winning hand label when available.
- The reveal holds for 5 seconds.
- After the hold, the table automatically starts the next hand when the session can continue.
- Quick/public/private/training tables all follow the same reveal rule, including local mock AI tables.

This uses the existing settlement result. It does not change dealing, betting, winner evaluation, or side-pot rules.

## Everyone Folded

When all but one player folded:

- No forced hole-card reveal happens.
- The result banner says everyone folded and names the pot winner.
- The result holds for 2.5 seconds.
- The table automatically starts the next hand when the session can continue.

Folded players' cards are not shown, and the winner's cards are not revealed just because they won by folds.

## Training

Training follows the same presentation rhythm:

- AI hole cards reveal only during showdown.
- Fold wins do not reveal AI cards.
- Training still uses practice chips only.
- Training hand results do not write account chips, gems, ranked stats, or wallet balances.

## Replay Prep

The local hand result includes presentation metadata for future replay work:

- `showdown_revealed_player_ids`
- `showdown_summary`
- `result_hold_seconds`
- `end_reason`: `showdown` or `everyone_folded`

Replay persistence is not implemented here. These fields simply describe the hand-end reveal stage so a future replay recorder can capture the same timing and visibility.

## Timer Safety

The poker table screen uses a pending next-hand token so only the newest hand-end timer can start the next hand. Returning to the lobby, resetting the debug table, or loading a debug phase cancels any pending timer before it can fire.

Manual next-hand input is not part of the formal flow. If retained for development, it must stay behind the debug tools flag and must not appear as player-facing copy.
