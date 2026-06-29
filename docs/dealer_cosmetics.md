# Dealer Cosmetics

Dealer Character is a local visual choice for the table dealer presentation. It is not the Texas Hold'em Dealer Button.

- Dealer Character changes the displayed dealer/croupier appearance.
- Dealer Button remains the rules position used for blinds, action order, and hand flow.
- Changing Dealer Character must not change dealer button position, dealing, blinds, betting, settlement, or table economy.

## Availability

Dealer Character selection is only available on solo/AI tables:

- `training_ai` tables can change Dealer Character.
- Tables with one local human and AI opponents can change Dealer Character.
- Tables with another human player cannot change Dealer Character.

Multiplayer tables disable this feature to avoid synchronization, host authority, and fairness disputes. This includes public tables with another human, Friends Room tables with another human, future server tables, and future Gem tables.

## Current Dealers

The first local list is:

- `default`
- `dog`
- `capybara`
- `lucky_cat`
- `raccoon`
- `stone_golem`

If an image resource is not available, the table may use a text/card placeholder. No Store, chip, or gem cost is attached.

## Future Server Rule

If Dealer Character selection ever becomes available in multiplayer, the selected dealer must come from a server-authoritative table snapshot. Clients must not unilaterally decide the shared multiplayer dealer appearance.
