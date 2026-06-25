# Poker Table Logic Frontend Handoff V1

This handoff describes stable logic fields for Antigravity. It does not request visual redesign.

## Stable Snapshot Fields

- `phase`: `preflop`, `flop`, `turn`, `river`, `showdown`, `finished`
- `current_turn_seat`
- `turn_seconds`
- `pot.main`
- `pot.side_pots`
- `community_cards`
- `seats`
- `available_actions`
- `events`
- `hand_complete`
- `winners`

## Seat Status Rendering

- `active`: normal playable seat
- `folded`: dim or folded state
- `all_in`: locked but still eligible for showdown
- `empty`: empty chair
- `disconnected`: future networking placeholder

## Actions

Render buttons only from `available_actions`.

Fields:

- `id`
- `label`
- `enabled`
- optional `amount`
- optional `min`
- optional `max`

The frontend must not implement poker legality. It should emit the selected action to backend/mock logic.

## Animation Events

Useful event types for future animation:

- `blind_posted`
- `hole_cards_dealt`
- `turn_started`
- `player_action`
- `community_cards_dealt`
- `showdown_started`
- `cards_revealed`
- `pot_awarded`
- `hand_finished`

## Backend Files Anti Must Not Edit

```text
scripts/core/
scripts/services/
scripts/demo/mock_table_simulation.gd
tests/
docs/contracts/
docs/backend/
```

## Placeholders

Side-pot settlement is only partially modeled. Hand evaluator coverage is smoke-test level, not exhaustive production certification.
