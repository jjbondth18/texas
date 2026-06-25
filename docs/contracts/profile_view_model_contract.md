# Profile ViewModel Contract

Provider:

```text
MockDataProvider.get_profile_view_model()
```

Shape:

```gdscript
{
  "sections": [
    {"id": "overview", "label": "Overview", "route": "profile"},
    {"id": "stats", "label": "Stats", "route": "profile_stats"},
    {"id": "achievements", "label": "Achievements", "route": "profile_achievements"},
    {"id": "cosmetics", "label": "Cosmetics", "route": "profile_cosmetics"}
  ]
}
```

This is a section skeleton only. Player stats and achievement details remain future backend work.
