# Dealer Cosmetics

Dealer Character is a local visual choice for the table dealer presentation. It is not the Texas Hold'em Dealer Button.

- Dealer Character changes the displayed dealer/croupier image.
- Dealer Button remains the rules position used for blinds, action order, and hand flow.
- Changing Dealer Character must not change dealer button position, dealing, blinds, betting, settlement, or table economy.

## Dealer Library

Dealer assets come from `assets/croupier/processed/`. The code uses `scripts/data/dealer_library.gd` as the single source of truth for dealer IDs, display names, and texture paths.

Current processed PNG resources:

- `dealer_01_dog.png` -> Dog
- `dealer_02_bear.png` -> Bear
- `dealer_03_cat.png` -> Cat
- `dealer_04_red_panda.png` -> Red Panda
- `dealer_05_armor.png` -> Armor
- `dealer_06_sloth.png` -> Sloth
- `dealer_07_statue.png` -> Statue
- `dealer_08_horse.png` -> Horse
- `dealer_09_owl.png` -> Owl
- `dealer_10_frog.png` -> Frog
- `dealer_11_walrus.png` -> Walrus

`selected_dealer_id` stores the stable resource ID, such as `dealer_07_statue`. Legacy `"default"` values are normalized to `dealer_01_dog`.

## Table UI

The Poker Table `DEALER` control opens a compact image-card picker near the top-right table controls. Each card shows the dealer PNG thumbnail and readable name. The current dealer preview, card label, and table croupier image all read from `DealerLibrary`, so the displayed image and name stay synchronized.

## Availability

Dealer Character selection is only available on solo/AI tables:

- `training_ai` tables can change Dealer Character.
- Tables with one local human and AI opponents can change Dealer Character.
- Tables with another human player cannot change Dealer Character.

Multiplayer tables disable this feature to avoid synchronization, host authority, and fairness disputes. This includes public tables with another human, Friends Room tables with another human, future server tables, and future Gem tables.

No Store, chip, or gem cost is attached.

## Future Server Rule

If Dealer Character selection ever becomes available in multiplayer, the selected dealer must come from a server-authoritative table snapshot. Clients must not unilaterally decide the shared multiplayer dealer appearance.
