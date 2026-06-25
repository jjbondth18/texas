# Hand Event Contract

Every hand event is a dictionary:

```gdscript
{
  "event_index": 12,
  "hand_id": "hand_000001",
  "type": "player_action",
  "phase": "flop",
  "seat_index": 4,
  "player_id": "player_004",
  "payload": {
    "action": "raise",
    "amount": 300
  }
}
```

## Event Types

- `hand_started`
- `dealer_assigned`
- `blind_posted`
- `hole_cards_dealt`
- `turn_started`
- `player_action`
- `action_rejected`
- `street_completed`
- `community_cards_dealt`
- `street_started`
- `showdown_started`
- `cards_revealed`
- `winner_determined`
- `pot_awarded`
- `hand_won_by_fold`
- `hand_finished`

## Privacy

`hole_cards_dealt` is marked as private payload metadata. Future networking should send hole-card detail only through private player snapshots.
