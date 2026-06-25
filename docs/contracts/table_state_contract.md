# Table State Contract

Core hand state shape:

```gdscript
{
  "hand_id": "hand_000001",
  "hand_number": 1,
  "phase": "preflop",
  "dealer_seat": 1,
  "small_blind_seat": 2,
  "big_blind_seat": 3,
  "current_turn_seat": 4,
  "small_blind": 25,
  "big_blind": 50,
  "current_bet": 50,
  "minimum_raise": 50,
  "pot": {"main": 75, "side_pots": []},
  "community_cards": [],
  "seats": [],
  "deck": [],
  "action_history": [],
  "events": [],
  "hand_complete": false,
  "winners": []
}
```

## Seat Fields

- `seat_index`
- `player_id`
- `player_name`
- `chips`
- `status`: `active`, `folded`, `all_in`, `empty`, `disconnected`
- `street_bet`
- `committed`
- `cards`
- `has_acted`
- UI compatibility fields may include `visual_position`, `is_local`, `is_dealer`, `is_small_blind`, `is_big_blind`, `is_turn`.

## Action Shape

```gdscript
{"id": "raise", "seat_index": 5, "amount": 300, "enabled": true}
```

Supported ids:

- `fold`
- `check`
- `call`
- `bet`
- `raise`
- `all_in`

Disabled or illegal actions append `action_rejected` and do not mutate the input dictionary.
