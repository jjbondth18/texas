# Backend Architecture V1

This pass establishes a backend/app contract foundation without changing Home Lobby frontend files.

## Layers

### App Layer

Path: `scripts/app/`

Responsibilities:

- route ids
- frontend-facing view models
- conversion from data models into dictionaries

Files:

- `app_routes.gd`
- `lobby_view_model.gd`
- `room_browser_view_model.gd`
- `table_view_model.gd`

### Data Layer

Path: `scripts/data/`

Responsibilities:

- simple typed data containers
- `to_dict()` conversion for UI contracts
- light `from_dict()` helpers

Files include player, currency, lobby mode, daily bonus, room, card, seat, table player, poker action, and table state skeletons.

### Demo Provider

Path: `scripts/demo/`

`MockDataProvider` owns local mock data for frontend integration until real services exist.

### Services

Path: `scripts/services/`

Skeleton services define future backend responsibilities:

- `ProfileService`
- `LobbyService`
- `TableService`

They currently delegate to `MockDataProvider`.

### Network

Path: `scripts/network/`

`NetworkService` is an offline placeholder. It does not connect to Steam, internet, or any backend.

## Non-Goals

This pass does not implement:

- poker hand rules
- matchmaking
- Steam API
- networking
- payment
- shop
- account system
- frontend layout

## Validation

Smoke test:

```powershell
& "C:\godot\Godot_v4.6.2-stable_win64.exe" --path "C:\Users\jjbon\Documents\texas" --script "res://tests/view_model_contract_smoke_test.gd"
```
