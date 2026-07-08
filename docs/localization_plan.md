# Localization Plan

Texas now has a first-pass localization layer for visible UI text.

## Language Packs

Language files live in `res://localization/`.

Supported locales:

- `en-US`
- `zh-CN`
- `zh-TW`
- `ja-JP`
- `ko-KR`
- `es-ES`
- `pt-BR`
- `fr-FR`
- `de-DE`
- `it-IT`
- `ru-RU`
- `tr-TR`

`en-US` is the complete fallback pack. Other locale packs contain the first batch of translated visible UI keys and fall back to `en-US` for missing keys.

## Runtime Manager

`scripts/services/localization_manager.gd` owns:

- `current_locale`
- `available_locales`
- `set_locale(locale)`
- `tr_key(key)`
- `trf(key, params)`

Missing locale files, unsupported locale ids, and missing keys fall back to `en-US`. If a key is still missing from `en-US`, the raw key is returned so broken strings are visible during development.

## Settings

Settings now stores `language_locale`.

The Settings page shows a native-language selector. Applying Settings:

1. Saves `language_locale`.
2. Updates `LocalizationManager.current_locale`.
3. Refreshes Home prompt, left nav, mode cards, Daily Bonus, and Settings immediately.

Some deeper screens are allowed to refresh on reopen during this first pass.

## Wired Areas

First-pass localized areas:

- Home navigation
- Home collapsed prompt
- Play mode cards
- Settings page
- Daily Bonus bar
- Replay Room title and primary replay entry text
- Store/Profile/Event page titles
- Avatar purchase confirmation
- ActionBar core labels
- PotDisplay title

Internal debug logs, server diagnostics, test messages, and table protocol payloads are intentionally not localized.

## Localization Audit Phase 2

The second audit pass expands localization coverage across the main player-facing surfaces:

- Quick Play setup, chip/gem mode switch, buy-in, blinds, hand-count options, and find-table actions.
- Public Room Browser headers, empty states, create/join buttons, public-table badges, and buy-in labels.
- Friends Room private-room setup, room-code labels, join form, and ready hints.
- Replay Room list/detail labels, unlock/replay buttons, lock states, section headers, and replay toasts.
- Store mock purchase labels, dev-only warnings, confirmation dialog, and result toasts.
- Profile overview, avatar gallery, avatar buy/select state, and avatar purchase feedback.
- Poker table waiting/ready panel, start warm-up button, exit/play-again buttons, sit-down failure messages, and table info labels.

New player-facing strings should be added as stable keys rather than inline English. Prefer grouped prefixes:

- `nav.*`
- `mode.*`
- `common.*`
- `quick.*`
- `setup.*`
- `browser.*`
- `friends.*`
- `table.*`
- `replay.*`
- `daily.*`
- `profile.*`
- `avatar.*`
- `store.*`
- `events.*`

Dynamic text uses `LocalizationManager.trf(key, params)`. Example:

```gdscript
LocalizationManagerScript.trf("avatar.confirm_text", {
	"name": avatar_name,
	"price": formatted_price,
})
```

All keys introduced in this audit pass are present in every one of the twelve locale files. Non-English packs may still use English fallback copy for newly introduced long-form strings until a native translation pass replaces them.

Do not localize protocol and diagnostic identifiers:

- `room_id` and `hand_id` values
- `table_type` values such as `public_chip`
- transaction reasons such as `table_buy_in`
- enum names, JSON keys, server logs, debug logs, resource paths, and test names
- card ranks, suit symbols, and raw replay record fields

## Fonts

Project assets were checked for `.ttf`, `.otf`, and `.ttc` files. No bundled CJK-capable font asset was found in `assets/` at the time of this pass. The current implementation relies on Godot/system fallback fonts for CJK text. A future polish pass should add a bundled UI font family with Simplified Chinese, Traditional Chinese, Japanese, and Korean coverage.
