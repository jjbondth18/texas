# Poker Table UI Contract

This project uses one objective 9-player table layout. Do not rotate the table around the local player.

## Seat Join Order

All 9-player table flows use this join order:

```gdscript
[5, 8, 2, 6, 4, 9, 1, 7, 3]
```

The first player sits at seat 5. The second player or AI sits at seat 8. The third sits at seat 2. The fourth sits at seat 6.

This applies to public rooms, local public warm-up AI, training AI, private room players, SeatCard rendering, and BetMarker rendering.

## Objective Seats

SeatCard, BetMarker, and PlayerStatus all bind to `seat_index`.

The desktop table must not rotate the local player to the bottom. The bottom personal panel may show the local player, but the table seats themselves stay objective and consistent across clients.

## BetMarker Anchors

BetMarker positions are fixed by `seat_index`.

They must not depend on PlayerStatus row order, dynamic name text, avatar position, current action text, current turn, or the local player's seat. Updating a bet amount should only change the marker label, not the marker anchor.

The implementation uses fixed design-space anchors in `SeatPlayerCard.BET_MARKER_ANCHORS_BY_SEAT`, converted from the stable `SeatPanel` origins. These anchors point toward the pot center and are shared by public authoritative tables, local public warm-up, and training.

Do not calculate BetMarker positions from SeatCard label width, avatar position, left status panel position, snapshot order, or client-local perspective.

## PlayerStatus Active Row

PlayerStatus rows use ascending `seat_index` order: 1 through 9. This is intentionally different from the table join order. If occupied seats are 5, 8, 2, and 6, the left status list renders 2, 5, 6, 8.

Turn changes may update highlight and apply a small horizontal active offset toward the table.

Rows must not reorder, resize, or rebuild just because the current turn changes. `current_turn_seat = -1` returns all rows to their neutral position.

## Bottom HUD Layout

All table modes use the same `ActionBar` / `BottomHud` component:

- Training
- Quick-created or Quick-matched public tables
- Browser-created or Browser-joined public tables
- Friends / private rooms
- Local AI warm-up
- Public official hands
- Private official hands

The bottom HUD has three fixed manual regions:

- `IdentityZone`: local player summary, anchored at `Vector2(0, 0)`.
- `FocusZone`: `YOUR HAND`, anchored at `Vector2(801, 0)`.
- `ControlZone`: bet and action controls, anchored at `Vector2(1157, 0)`.

The left and middle regions must not move when tuning the middle-to-right spacing. If the `YOUR HAND` to action gap needs adjustment, move only `ControlZone` or add a dedicated spacer between the middle and right regions. Do not change a global container separation, because the left-to-middle gap is already part of the contract.

Action controls inside `ControlZone`, including the slider, quick bet buttons, main action buttons, and `BET AMOUNT` value label, must keep their internal layout unless a task explicitly targets those controls.

## Community Card Reveal

Community cards are dealt visually from the dealer area to the center of the public board reveal area, not to per-slot final positions.

The temporary flying card uses `res://assets/ui/cardback/asset_01.png`, lands at `CommunityBoard.get_deal_reveal_center_global()`, flips face-up there, and is then committed to `CommunityBoard`. `CommunityBoard` owns the final centered layout for the visible board cards after each card is revealed.

Flop, Turn, and River all follow the same rule. The three Flop cards are still revealed one at a time, and each new card flies to the same board-center reveal point before the board re-centers the visible cards.

## Freeze Rule

Server authority, Ready flow, Replay work, warm-up, private rooms, and mode entry changes must not break this UI contract. Any table feature that needs to show poker state should bind to `seat_index`, the shared `BottomHud`, fixed BetMarker anchors, and the board-center community-card reveal behavior rather than introducing a separate layout path.
