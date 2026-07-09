# Localization Source Audit

This audit separates visible English sources by intent so localization work can target player-facing copy without mutating identifiers, debug data, or gameplay state.

## A. MUST_LOCALIZE

These strings are player-facing UI copy and must be rendered through localization keys.

- Home and Play mode cards: `QUICK PLAY`, `ROOM BROWSER`, `FRIENDS ROOM`, `TRAINING`, `EVENTS`, and their descriptions.
- Left navigation and top bar: `PLAY`, `REPLAY`, `STORE`, `PROFILE`, `SETTINGS`, `CHIPS`, `GEMS`, `SOCIAL`, `HELP`, `EXIT`, `LEVEL`.
- Daily Bonus: `Cycle Progress`, `Today: Claim Day`, `Next Reward`, `CLAIM`, `CLAIMED`, `CLAIMED TODAY`, `NEXT`, `LOCKED`, day labels, chips/XP/gems reward labels.
- Store: tab titles, mock purchase copy, pack buttons, confirm dialog text, success/failure toasts.
- Profile: `STATISTICS & UNLOCKED ACHIEVEMENTS`, `OVERVIEW & STATS`, stat labels, `CHARACTER AVATARS`, avatar purchase states, profile title/level/XP, selected avatar label.
- Data-driven Profile metadata: avatar display names, achievement names, achievement descriptions, achievement status labels, and title unlock names.
- Events: page title, subtitle, event card names/descriptions, coming-soon status, no-charge note, back button.
- Social and Help modals: modal titles, help section titles, rules, mode descriptions, and currency explanations.
- Replay Room / Replay Detail: hand list copy, unlock/play buttons, section headers, timeline labels, static viewer hints.
- PokerTableScreen and ReplayPokerTableScreen visible controls: table action buttons, pot/hand/action labels, replay controls, status prompts, exit/confirm dialogs.

## B. OPTIONAL_DEV_ONLY

These are development/testing labels. If a production build hides them, they may remain English; if visible to players in the current build, they should still use localization keys.

- `MOCK PURCHASE`
- `DEV ONLY`
- `Mock Buy 10,000 Chips`
- `Mock wallet packs for local development testing.`
- Server-authoritative wallet sync debug snippets shown in table logs.
- Dev identity/debug launch messages.
- Mock room or local backend diagnostics.

## C. KEEP_ENGLISH

These are intentionally not translated because they are identifiers, brand marks, poker notation, or developer-only diagnostics.

- Brand/logo text: `TEXAS HOLD'EM`, `POKER CLUB`.
- Player names such as `Luna0581` and `DevPlayer2`.
- Runtime identifiers: `room_1`, `hand_000010`, `player_id`, `room_id`, `hand_id`.
- Enum values and database fields: `public_chip`, `private_gem`, `table_buy_in`, `replay_unlock`.
- JSON keys, resource paths, file paths, server logs, debug logs, and test names.
- Card ranks and symbols: `A`, `K`, `Q`, `J`, `10`, suit symbols.
- Poker abbreviations that are common shorthand in UI, such as `NLH`, when used as table format notation.

## Data-Driven Copy Rules

- UI definitions should keep stable internal ids, such as `quick_play`, `first_blood`, or `4_05`.
- Display names should use localization keys, for example `mode.quick_play.title`, `achievement.first_blood.name`, and `avatar.4_05.name`.
- If a localization key is missing for cosmetic metadata, the UI may fall back to the internal English display name, but the first-party visible catalog should define keys.
- Transaction reasons, table types, and ids remain raw internal values and should not be translated.

## Current Phase 3 Cleanup

- Top bar currency/action labels now use localization keys.
- Home CTA, Social, Help, and Events visible copy now use localization keys.
- Daily Bonus day/toast fragments now use localization keys.
- Profile achievements, avatar display names, avatar purchase prompts, and level titles are displayed through localization keys.
- `zh-CN` has explicit translations for the main Home, Store, Profile, Daily Bonus, Events, Social, and Help surfaces covered by this audit.
