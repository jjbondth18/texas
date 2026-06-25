# Frontend / Backend Contract Overview

This project is split between two agents.

## Codex Ownership

Codex owns backend/app architecture:

- `scripts/app/`
- `scripts/core/`
- `scripts/data/`
- `scripts/services/`
- `scripts/network/`
- `scripts/demo/`
- `tests/`
- `docs/backend/`
- `docs/contracts/`

## Frontend Ownership

Frontend work is owned by Gemini / Antigravity:

- Godot scenes
- UI scripts
- components
- layout
- animation
- assets and screenshots

Codex should not edit frontend files during backend tasks.

## Current Contract Entry Points

- `AppRoutes`: stable route ids.
- `MockDataProvider.get_lobby_view_model()`: Home Lobby data.
- `MockDataProvider.get_room_browser_view_model()`: room browser data.
- `MockDataProvider.get_table_view_model()`: table screen skeleton data.

Frontend should bind to these dictionaries instead of scattering mock data across UI scripts.

## Replacement Strategy

Today all providers return local mock data. Later, services can replace internals with Steam, online backend, local save, or host authority data while preserving the same ViewModel shape.
