# Poker Table Layout Calibrator

Open this scene to edit the large poker table layout boxes without cluttering the real Poker Table scene:

```text
res://scenes/dev/poker_table_layout_calibrator.tscn
```

The scene is editor-visible. `TableBackground`, `LayoutBoxes`, each named layout box, and `HelpOverlay` are real nodes in the `.tscn`, so they appear in the scene tree and 2D editor without pressing Play.

## Controls

- click a box: select
- drag: move
- drag lower-right corner: resize
- `Shift + drag`: resize
- arrow keys: nudge
- `Shift + arrow`: large nudge
- `Tab`: cycle selected box
- `Ctrl + S`: save JSON
- `Ctrl + R`: reset to defaults

## Save Location

The calibrator writes to:

```text
user://poker_table_layout_config.json
```

The real Poker Table consumes this JSON when it opens.

Saving reads the current rects from the real `LayoutBoxes` child nodes. If you move or resize boxes in the Godot editor, run the calibrator scene and press `Ctrl + S` to write those editor-authored rects to the user JSON.

## Runtime Validation

Generated screenshots:

```text
docs/screenshots/poker_table_layout_calibrator.png
docs/screenshots/runtime_table_after_calibrator_layout.png
```

Capture commands:

```powershell
& "C:\godot\Godot_v4.6.2-stable_win64.exe" --path "C:\Users\jjbon\Documents\texas" "res://scenes/dev/poker_table_layout_calibrator.tscn" -- --capture-output "C:\Users\jjbon\Documents\texas\docs\screenshots\poker_table_layout_calibrator.png"
& "C:\godot\Godot_v4.6.2-stable_win64.exe" --path "C:\Users\jjbon\Documents\texas" --script "res://tests/poker_table_runtime_capture.gd" --capture-table-phase preflop --capture-output "C:\Users\jjbon\Documents\texas\docs\screenshots\runtime_table_after_calibrator_layout.png"
```

## Repository Default

The default committed layout lives at:

```text
docs/frontend/poker_table_layout_config.default.json
```

Runtime edits are not automatically committed. If you like a layout, copy the user JSON into that file manually.

## Editable Boxes

```text
seat_1
seat_2
seat_3
seat_4
seat_5_local
seat_6
seat_7
seat_8
seat_9
left_panel
right_panel
bottom_hud
pot_display
community_board
dealer_indicator
```

This scene is a clean calibration tool only. It contains no gameplay logic, real action buttons, chat text, player avatars, or nested panel guides.
