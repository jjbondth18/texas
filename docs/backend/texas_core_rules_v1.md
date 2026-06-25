# Texas Hold'em Core Rules V1

This backend-only pass creates the first testable Texas Hold'em core rules skeleton.

## Scope

Implemented in this pass:

- card model
- standard 52-card deck generation
- deck shuffle and draw
- poker phase constants
- betting action constants
- betting state container
- hand rank constants
- partial hand evaluator
- table state reducer skeleton
- mock table simulation
- smoke test

Not implemented in this pass:

- complete production hand comparison
- side pots
- blind rotation
- turn order enforcement
- all-in settlement
- network authority
- UI
- Steam integration

## Card Format

Cards are dictionaries:

```gdscript
{
  "rank": "A",
  "suit": "spades",
  "code": "AS"
}
```

Ranks:

```text
2 3 4 5 6 7 8 9 T J Q K A
```

Suits:

```text
clubs diamonds hearts spades
```

Suit codes:

```text
C D H S
```

## Deck

`scripts/core/deck.gd` generates a standard 52-card deck.

Supported:

- `reset()`
- `shuffle(seed_value := 0)`
- `draw(count_to_draw := 1)`
- `count()`
- `codes()`
- `has_unique_codes()`

Smoke test validates 52 cards, unique codes, and draw count reduction.

## Poker Phases

`scripts/core/poker_phase.gd` defines:

```text
waiting
preflop
flop
turn
river
showdown
finished
```

## Betting Actions

`scripts/core/betting_action.gd` defines:

```text
fold
check
call
bet
raise
all_in
small_blind
big_blind
sit_out
```

Action shape:

```gdscript
{
  "id": "call",
  "player_id": "player_1",
  "amount": 50,
  "enabled": true
}
```

This is only a stable contract. Full betting legality is not implemented yet.

## Hand Ranks

`scripts/core/hand_rank.gd` defines ranks low to high:

```text
high_card
one_pair
two_pair
three_of_a_kind
straight
flush
full_house
four_of_a_kind
straight_flush
royal_flush
```

Evaluator output:

```gdscript
{
  "rank": "one_pair",
  "rank_value": 1,
  "cards": ["AS", "AD", "7C", "5H", "2S"],
  "kickers": ["7C", "5H", "2S"]
}
```

The current evaluator detects common rank categories in a stable way for skeleton/testing purposes. It is not yet a complete production evaluator for every seven-card tie-break scenario.

## Table State Reducer

`scripts/core/table_state_reducer.gd` exposes:

```gdscript
apply_action(table_state: Dictionary, action: Dictionary) -> Dictionary
```

Current behavior:

- validates basic action shape
- validates known action ids
- duplicates input state instead of mutating it
- appends normalized action to `action_history`
- increments `pot` for amount-based actions
- writes `last_error = "invalid_action_shape"` for invalid input

## Mock Table Simulation

`scripts/demo/mock_table_simulation.gd` returns:

```gdscript
{
  "table_id": "mock_table_001",
  "phase": "preflop",
  "deck_count": 52,
  "community_cards": [],
  "pot": 75,
  "seats": [],
  "available_actions": [
    {"id": "fold", "label": "Fold", "enabled": true},
    {"id": "call", "label": "Call 50", "enabled": true, "amount": 50},
    {"id": "raise", "label": "Raise", "enabled": true, "min": 100, "max": 1000}
  ]
}
```

Future Poker Table UI can rely on this as a backend-owned shape, but no UI is implemented here.

## Smoke Test

Run:

```powershell
& "C:\godot\Godot_v4.6.2-stable_win64.exe" --path "C:\Users\jjbon\Documents\texas" --script "res://tests/texas_core_smoke_test.gd"
```

Expected output:

```text
Texas core smoke test passed.
```
