# Poker Table Functional Slice

This slice creates a functional 9-seat Texas Hold'em table screen for runtime validation and future visual polish.

## Runtime Scene

```text
res://scenes/screens/poker_table_screen.tscn
```

The scene uses the approved table background:

```text
res://assets/poker_table/backgrounds/table_neon_v1.png
```

The layout follows the approved `2560 x 1000` virtual design canvas:

- left information panel: 320 px
- center poker table zone: 1920 px
- right status panel: 320 px
- bottom action region: about 240 px

The runtime scales this virtual canvas proportionally to the current viewport.

## Developer Controls

- `1`: preflop snapshot
- `2`: flop snapshot
- `3`: turn snapshot
- `4`: river snapshot
- `5`: showdown snapshot
- `R`: reset to preflop
- `Esc`: close the table window

## Implemented Functional Pieces

- 9 visual seats
- Seat 5 local-player presentation position
- top-center dealer indicator
- movable dealer marker in seat data
- community board with 0/3/4/5 card behavior by phase
- local hole cards face-up
- opponent cards face-down except showdown
- pot display
- per-seat current bet display
- action bar driven by `available_actions`
- fold/call/raise mock action flow
- left hand history / system message panel
- right table status panel
- 15-second mock timer label

## Mock-Only Behavior

- no real networking
- no poker-rule authority
- no production betting validation
- no final visual polish
- no real countdown authority
- no persisted hand history

Action buttons call `MockTableSimulation.apply_mock_action(...)`, which delegates amount changes through the existing reducer path where possible.
