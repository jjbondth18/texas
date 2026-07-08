# Profile Progression

Profile progression is a lightweight account-display layer. It does not grant table power, improve card odds, change matchmaking, or affect wallet settlement.

## Daily Bonus

Daily Bonus is claimed from the Home page with the `CLAIM` button. Rewards use a simple seven-day loop and do not reset for missed days in the first version.

| Day | Chips | XP | Gems |
| --- | ---: | ---: | ---: |
| 1 | 500 | 25 | 0 |
| 2 | 750 | 25 | 0 |
| 3 | 1,000 | 25 | 0 |
| 4 | 1,250 | 25 | 0 |
| 5 | 1,500 | 25 | 0 |
| 6 | 2,000 | 25 | 0 |
| 7 | 5,000 | 50 | 5 |

Each natural day can be claimed once. After claiming Day 7, the next eligible claim returns to Day 1.

The chip, XP, and Gem rewards share the same once-per-day claim rule. If the daily bonus has already been claimed for the current date, no reward is granted again.

## Level

Level is derived from lifetime XP:

```text
level = floor(total_xp / 100) + 1
```

Profile displays XP as progress inside the current level:

```text
Level 3
XP 40 / 100
```

## Titles

The Profile page displays the best title unlocked by the current level.

| Level | Title |
| --- | --- |
| 1 | Rookie |
| 3 | Casual Player |
| 5 | Table Regular |
| 10 | Sharp Caller |
| 15 | River Hunter |
| 20 | Card Shark |
| 30 | High Roller |
| 50 | Poker Legend |

Titles are shown only on the Profile page for now. They do not appear on the table HUD, do not affect gameplay, and are not part of a mission, battle pass, or achievement system.

## Avatar Purchases

Ordinary Character Avatars use Chips only.

- Selected avatar: `SELECTED`
- Owned avatar: `SELECT`
- Locked and affordable: `Buy 7,500 Chips`
- Locked and unaffordable: `Need 7,500 Chips`

Purchasing an avatar deducts chips from the account wallet, unlocks the avatar, saves the profile, and selects the new avatar. Avatar purchases never spend Gems and never touch table stacks.

Locked avatar purchases show a confirmation dialog:

```text
Confirm Purchase
Buy {Avatar Name} for {price} Chips?
```

Cancel closes the dialog with no charge. Confirm checks the current chip balance, deducts chips, unlocks the avatar, and selects it.

Gems remain reserved for replay unlocks and future premium features.
