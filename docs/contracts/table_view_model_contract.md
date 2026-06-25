# Table ViewModel Contract

Provider:

```text
MockDataProvider.get_table_view_model()
```

Shape:

```gdscript
{
  "table_id": "mock_table_001",
  "table_name": "Neon Table 01",
  "blinds_text": "25 / 50",
  "pot": 400,
  "phase": "preflop",
  "community_cards": [],
  "seats": [],
  "local_player": {},
  "available_actions": []
}
```

## Required Fields

- `table_id`: stable table identifier.
- `table_name`: display name.
- `blinds_text`: already formatted blind display string.
- `pot`: current pot amount.
- `phase`: table phase, initially mock values such as `preflop`.
- `community_cards`: array of card dictionaries.
- `seats`: array of seat/player dictionaries.
- `local_player`: local player table snapshot.
- `available_actions`: UI-facing action list.

## Future Action Examples

```gdscript
[
  {"id": "fold", "label": "Fold", "enabled": true},
  {"id": "check", "label": "Check", "enabled": false},
  {"id": "call", "label": "Call 50", "enabled": true, "amount": 50},
  {"id": "raise", "label": "Raise", "enabled": true, "min": 100, "max": 1000}
]
```

Task A does not implement poker rules. This contract only reserves the frontend shape.
