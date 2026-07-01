# Poker Table UI Contract

This project uses one objective 9-player table layout. Do not rotate the table around the local player.

## Seat Join Order

All 9-player table flows use this join order:

```gdscript
[5, 8, 2, 6, 4, 9, 1, 7, 3]
```

The first player sits at seat 5. The second player or AI sits at seat 8. The third sits at seat 2. The fourth sits at seat 6.

This applies to public rooms, local public warm-up AI, training AI, private room players, Player Status rows, SeatCard rendering, and BetMarker rendering.

## Objective Seats

SeatCard, BetMarker, and PlayerStatus all bind to `seat_index`.

The desktop table must not rotate the local player to the bottom. The bottom personal panel may show the local player, but the table seats themselves stay objective and consistent across clients.

## BetMarker Anchors

BetMarker positions are fixed by `seat_index`.

They must not depend on PlayerStatus row order, dynamic name text, avatar position, current action text, current turn, or the local player's seat. Updating a bet amount should only change the marker label, not the marker anchor.

## PlayerStatus Active Row

PlayerStatus rows use the fixed 9-player seat join order. Turn changes may update highlight and apply a small horizontal active offset toward the table.

Rows must not reorder, resize, or rebuild just because the current turn changes. `current_turn_seat = -1` returns all rows to their neutral position.
