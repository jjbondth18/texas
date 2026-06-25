# Lobby ViewModel Contract

Provider:

```text
scripts/demo/mock_data_provider.gd
MockDataProvider.get_lobby_view_model()
```

App model:

```text
scripts/app/lobby_view_model.gd
```

## Shape

```gdscript
{
  "player": {
    "name": "Luna0581",
    "level": 24,
    "xp_text": "875 / 1500 XP",
    "chips": 25750,
    "gems": 1250,
    "avatar": "res://assets/home_lobby/profile/avatar_placeholder.png"
  },
  "main_nav": [
    {"id": "home", "label": "HOME", "route": "home"},
    {"id": "play", "label": "PLAY", "route": "play"},
    {"id": "replay", "label": "REPLAY", "route": "replay"},
    {"id": "store", "label": "STORE", "route": "store"},
    {"id": "profile", "label": "PROFILE", "route": "profile"},
    {"id": "settings", "label": "SETTINGS", "route": "settings"}
  ],
  "modes": [
    {
      "id": "quick_play",
      "title": "QUICK PLAY",
      "subtitle": "Jump into a table instantly",
      "route": "quick_play",
      "enabled": true
    }
  ],
  "daily_bonus": {
    "current_day": 4,
    "days": [
      {"day": 1, "reward": 500, "claimed": true}
    ]
  }
}
```

## Required Fields

### `player`

- `name`: display name.
- `level`: numeric player level.
- `xp_text`: already formatted XP string for frontend display.
- `chips`: free currency balance.
- `gems`: premium/mock currency balance.
- `avatar`: resource path. Mock placeholder for now.

### `modes[]`

Exactly five PLAY mode cards are provided for the current contract: `quick_play`, `room_browser`, `private_table`, `training`, and `events`.

- `id`: stable mode id.
- `title`: frontend display title.
- `subtitle`: short frontend display subtitle.
- `route`: route id frontend should emit when selected.
- `enabled`: whether the frontend should allow selection.

### `daily_bonus`

- `current_day`: current highlighted day.
- `days[]`: seven reward rows.
- `days[].day`: day number.
- `days[].reward`: reward amount.
- `days[].claimed`: claim state.

## Mock Status

All values are local mock data. Future backend services can replace `MockDataProvider` without changing frontend field names.
