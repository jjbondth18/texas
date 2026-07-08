# Profile Progression

Profile progression is a lightweight account-display layer. It does not grant table power, improve card odds, change matchmaking, or affect wallet settlement.

## Daily Login XP

The daily login reward grants:

- `+1,000 Chips`
- `+25 XP`

The chip and XP reward share the same once-per-day claim rule. If the daily login has already been claimed for the current date, neither chips nor XP are granted again.

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

Gems remain reserved for replay unlocks and future premium features.
