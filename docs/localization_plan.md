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

## Fonts

Project assets were checked for `.ttf`, `.otf`, and `.ttc` files. No bundled CJK-capable font asset was found in `assets/` at the time of this pass. The current implementation relies on Godot/system fallback fonts for CJK text. A future polish pass should add a bundled UI font family with Simplified Chinese, Traditional Chinese, Japanese, and Korean coverage.
