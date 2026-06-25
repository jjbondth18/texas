# Poker Table Frontend Handoff V1

Codex created the functional table slice. Antigravity/Gemini can polish presentation without changing backend contracts.

## Anti May Modify

```text
scenes/screens/poker_table_screen.tscn
scripts/screens/poker_table_screen.gd
scenes/components/poker_*.tscn
scripts/components/poker_*.gd
scenes/components/card_view.tscn
scripts/components/card_view.gd
themes/
assets/poker_table/
shaders/
docs/frontend/
docs/screenshots/
```

## Anti Must Not Modify

```text
scripts/app/table_view_model.gd
scripts/core/table_state_reducer.gd
scripts/demo/mock_table_simulation.gd
scripts/core/hand_evaluator.gd
tests/
docs/contracts/
docs/backend/
```

## Stable Snapshot Fields

Frontend can rely on these fields from `MockTableSimulation.get_phase_snapshot(...)`:

- `table_id`
- `table_name`
- `blinds_text`
- `phase`
- `community_cards`
- `pot`
- `pot_data.main`
- `pot_data.side_pots`
- `seats`
- `local_player`
- `dealer_seat_index`
- `local_seat_index`
- `turn_seat_index`
- `turn_seconds`
- `available_actions`
- `hand_history`
- `system_messages`

## Seat Fields

Each seat provides:

- `seat_index`
- `visual_position`
- `player_id`
- `player_name`
- `avatar`
- `chips`
- `current_bet`
- `status`
- `is_local`
- `is_dealer`
- `is_small_blind`
- `is_big_blind`
- `is_turn`
- `cards`

`seat_index` is data identity. `visual_position` is screen placement. Do not permanently tie networking seat IDs to visual positions.

## Card Fields

Each card provides:

- `rank`
- `suit`
- `face_up`

Valid suits are `clubs`, `diamonds`, `hearts`, and `spades`. Valid ranks are `2 3 4 5 6 7 8 9 T J Q K A`.

## Action Fields

Each action provides:

- `id`
- `label`
- `enabled`
- optional `amount`
- optional `min`
- optional `max`

The action bar should render buttons only from `available_actions`. It must not implement poker rules.
