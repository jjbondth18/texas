extends SceneTree


func _init() -> void:
	var panel_source: String = FileAccess.get_file_as_string("res://scripts/components/table_room_info_panel.gd")
	var table_source: String = FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	_require(panel_source.find("RoomIdLabel") != -1, "Table info panel must have a dedicated Room label.")
	_require(panel_source.find("Room: %s") != -1, "Table info panel must render Room: <room_id>.")
	_require(panel_source.find("Hand ID: %s") != -1, "Hand id must be separate from room id.")
	_require(table_source.find("_room_label_from_snapshot") != -1, "Poker table must derive a room label from snapshots.")
	_require(table_source.find("\"room_label\"") != -1, "Server/local snapshots must expose room_label.")
	print("Table info room id required test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
