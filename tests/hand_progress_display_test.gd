extends SceneTree

const TableRoomInfoPanelScript := preload("res://scripts/components/table_room_info_panel.gd")

func _initialize() -> void:
	var panel := TableRoomInfoPanelScript.new()
	root.add_child(panel)
	await process_frame

	panel.set_table_context("preflop", "hand_000003", 5, "25 / 50")
	panel.set_hand_progress("Hand 3 / 10")
	await process_frame

	var progress_label: Label = panel.find_child("HandProgressLabel", true, false) as Label
	var hand_label: Label = panel.find_child("HandIdLabel", true, false) as Label
	_require(progress_label != null, "hand progress label must exist")
	_require(progress_label.text == "Hand 3 / 10", "hand progress label must show session count")
	_require(hand_label != null and hand_label.text == "ID: hand_000003", "hand id label must be separate from progress")

	print("Hand progress display test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
