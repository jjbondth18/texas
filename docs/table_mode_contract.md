# Table Mode Contract

This document freezes the current table-mode behavior before Replay work. It describes how players enter tables and which systems are allowed to affect wallet, server rooms, and official hand state.

## Shared Table Shell

All modes render through the same poker table shell and bottom HUD. Mode-specific logic may change data, labels, network authority, or practice isolation, but must not fork the table layout, SeatCard contract, BetMarker anchors, PlayerStatus ordering, or ActionBar layout.

Official public/private room creation assigns a stable `dealer_id` for the room. Local public, private, training, and warm-up contexts also carry a dealer id for presentation and replay thumbnails. Dealer selection is visual metadata only; it must not affect dealing, betting, showdown, wallet, gems, or mode entry rules.

## Quick

Quick is not an independent poker rules mode. It is an automatic matcher over public tables.

- It uses the selected buy-in, blinds, and hand count as matching preferences.
- Quick Chip only matches `public_chip` tables with `currency = chips`.
- Quick Gem only matches `public_gem` tables with `currency = gems`.
- Quick Chip and Quick Gem never cross-match.
- It does not join private rooms, training tables, local warm-up tables, full tables, closed tables, or `session_complete` tables.
- In the current version it also avoids active `playing` / `hand_result` tables.
- If no valid public table matches, it creates a new public table with the selected config and currency.
- Quick Gem uses Gem buy-ins `20/50/100/200`, blinds `1/2`, `2/5`, or `5/10`, and the same hand-count options as Quick Chip.
- Quick Gem checks the server/local Gem wallet before entering a table and shows `Not enough gems. Visit Store to get more gems.` when the selected buy-in is unaffordable.
- The resulting table enters the normal public waiting / Ready flow and may offer local AI warm-up while waiting for real players.

## Browser

Browser is the manual public chip table flow.

- It lists public chip tables.
- It can manually create public chip tables.
- It can manually join public chip tables.
- Public Gem tables are entered through Quick Gem matchmaking in this version.
- It must not list private rooms.
- It shares the same server/local public table registry that Quick uses.

## Friends Room

Friends Room is the private room-code flow.

- Creating a Friends Room creates a private chip or private gem room and generates a room code.
- Joining requires the room code.
- Private rooms do not appear in Browser.
- Quick never matches private rooms.
- Private Chip uses `table_type = private_chip`, `currency = chips`.
- Private Gem uses `table_type = private_gem`, `currency = gems`.
- Private Gem joins reject players whose Gem wallet cannot cover the selected buy-in.
- Private rooms reuse the same seat, Ready, hand, result, session-complete, exit, and cash-out mechanics as public chip rooms.

## Training

Training is a local AI practice mode.

- It does not use the authoritative server table room.
- It uses practice-only chips.
- It does not affect wallet chips, gems, public stats, formal hand results, or table profit.
- It still uses the shared table UI contract and objective seat mapping.

## Local AI Warm-Up

Local AI warm-up is a waiting-room practice flow.

- It can run while a public room waits for real players.
- Its AI players stay local and never enter the server room.
- It uses practice-only chips and does not affect wallet chips, gems, public stats, or formal hand results.
- If a real player joins the underlying room, warm-up stops and the client applies the latest real room snapshot.
- Warm-up must not change public/private official hand state.

## Public And Private Official Hands

Official public and private hands use the authoritative room/session flow.

- Players sit, then use Ready according to the room rules.
- Once the official session starts, later hands continue automatically while enough eligible ready players remain.
- Mid-hand joiners wait for the next hand according to the room rules.
- When the configured hand count is reached, the session enters `session_complete`.
- Exit and cash-out rules apply only to official table stacks, not to local practice warm-up or training chip results.
- Chip official tables settle Chips. Gem official tables settle Gems.
- Gem table wallet transactions use `gem_table_buy_in`, `gem_left_before_official_hand`, `gem_table_cash_out`, and `gem_session_complete_cash_out`.

## Replay Boundary

Replay work may read snapshots, hand events, and mode metadata, but it must not mutate live table state, alter mode entry behavior, or introduce a parallel table UI layout.
