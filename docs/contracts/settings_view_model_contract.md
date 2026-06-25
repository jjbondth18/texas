# Settings ViewModel Contract

Provider:

```text
MockDataProvider.get_settings_view_model()
```

Shape:

```gdscript
{
  "sections": [
    {"id": "graphics", "label": "Graphics", "route": "settings_graphics"},
    {"id": "audio", "label": "Audio", "route": "settings_audio"},
    {"id": "controls", "label": "Controls", "route": "settings_controls"},
    {"id": "language", "label": "Language", "route": "settings_language"},
    {"id": "motion", "label": "Motion", "route": "settings_motion"}
  ]
}
```

This is a navigation skeleton only. It does not change `project.godot`, autoloads, input maps, or runtime settings.
