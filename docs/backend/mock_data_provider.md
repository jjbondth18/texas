# Mock Data Provider

File:

```text
scripts/demo/mock_data_provider.gd
```

The mock provider is the single backend-owned source of UI-facing mock data.

## Methods

- `get_lobby_view_model() -> Dictionary`
- `get_room_browser_view_model() -> Dictionary`
- `get_table_view_model() -> Dictionary`
- `get_mock_rooms() -> Array[Dictionary]`
- `get_mock_player_profile() -> Dictionary`

## Contract Use

Frontend can initially bind to the returned dictionaries. When real backend work begins, service internals can change while preserving these shapes.

## Current Limitations

- No network calls.
- No database.
- No Steam API.
- No real economy.
- No poker rules engine.
- No persisted player profile.

## Smoke Test

Run:

```powershell
& "C:\godot\Godot_v4.6.2-stable_win64.exe" --path "C:\Users\jjbon\Documents\texas" --script "res://tests/view_model_contract_smoke_test.gd"
```
