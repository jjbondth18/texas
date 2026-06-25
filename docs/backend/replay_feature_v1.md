# Replay Feature V1

Replay is a first-class product area for reviewing previous Texas Hold'em hands.

## V1 Scope

- Basic replay history is available to free users.
- Replay records expose table name, result, net chips, hero cards, final board, and biggest pot.
- Replay Pro is represented by locked analysis fields.
- Equity timeline data is mock-only in this version.

## Monetization Intent

Replay Pro should unlock deeper review modules:

- street-by-street action review
- win probability / equity timeline
- major decision markers
- future hand-strength and range analysis

No payment, Steam API, wallet, or entitlement implementation exists in this contract pass.

## Future Backend Work

Real equity should be calculated from persisted table state snapshots, hero cards, known board cards, and opponent ranges or revealed hands. Current values are static mock data for frontend integration.
