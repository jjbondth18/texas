# Replay ViewModel Contract

Provider:

```text
scripts/demo/mock_data_provider.gd
MockDataProvider.get_replay_view_model()
```

App model:

```text
scripts/app/replay_view_model.gd
```

## Shape

```gdscript
{
  "summary": {
    "total_replays": 42,
    "free_replay_limit": 5,
    "analysis_unlocked": false
  },
  "filters": [
    {"id": "all", "label": "All"},
    {"id": "wins", "label": "Wins"},
    {"id": "losses", "label": "Losses"},
    {"id": "big_pots", "label": "Big Pots"},
    {"id": "favorites", "label": "Favorites"}
  ],
  "records": [
    {
      "replay_id": "replay_001",
      "played_at": "2026-06-25 22:41",
      "mode": "Quick Play",
      "table_name": "Neon Table 01",
      "result": "win",
      "net_chips": 1250,
      "hero_cards": [
        {"code": "AS", "rank": "A", "suit": "spades"},
        {"code": "KS", "rank": "K", "suit": "spades"}
      ],
      "final_board": ["QS", "JS", "2D", "7C", "TH"],
      "biggest_pot": 4200,
      "analysis_available": true,
      "analysis_locked": true,
      "favorite": false
    }
  ],
  "selected_replay": {
    "replay_id": "replay_001",
    "street_actions": [],
    "equity_timeline": [
      {"step": 0, "street": "preflop", "hero_equity": 0.64},
      {"step": 1, "street": "flop", "hero_equity": 0.78},
      {"step": 2, "street": "turn", "hero_equity": 0.31},
      {"step": 3, "street": "river", "hero_equity": 0.0}
    ],
    "premium_required": true
  }
}
```

## Product Intent

Replay is a major monetization feature. Free users can see basic hand history and replay records. Replay Pro unlocks detailed street review, equity timeline, and future analysis modules.

`equity_timeline` is mock data for now. A future backend service will calculate real equity from recorded table state and revealed cards.
