# Store ViewModel Contract

Provider:

```text
MockDataProvider.get_store_view_model()
```

Shape:

```gdscript
{
  "tabs": [
    {"id": "chips", "label": "Chips", "route": "store_chips"},
    {"id": "replay_pro", "label": "Replay Pro", "route": "store_replay_pro"},
    {"id": "cosmetics", "label": "Cosmetics", "route": "store_cosmetics"},
    {"id": "membership", "label": "Membership", "route": "store_membership"}
  ]
}
```

This is a navigation skeleton only. Real products, pricing, Steam purchase state, and wallet data are intentionally out of scope.
