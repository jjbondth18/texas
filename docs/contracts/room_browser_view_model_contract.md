# Room Browser ViewModel Contract

Provider:

```text
MockDataProvider.get_room_browser_view_model()
```

Shape:

```gdscript
{
  "rooms": [
    {
      "room_id": "mock_room_001",
      "name": "Neon Table 01",
      "mode": "cash_tables",
      "players": 4,
      "max_players": 6,
      "small_blind": 25,
      "big_blind": 50,
      "buy_in_min": 1000,
      "buy_in_max": 10000,
      "status": "open",
      "is_private": false
    }
  ]
}
```

## Required Room Fields

- `room_id`: stable room identifier.
- `name`: display name.
- `mode`: route/mode id such as `cash_tables`.
- `players`: current seated or listed players.
- `max_players`: capacity.
- `small_blind`: small blind amount.
- `big_blind`: big blind amount.
- `buy_in_min`: minimum buy-in.
- `buy_in_max`: maximum buy-in.
- `status`: mock status such as `open` or `locked`.
- `is_private`: whether the room requires invitation/access.

This is not matchmaking. It is a frontend contract for future room browser UI.
