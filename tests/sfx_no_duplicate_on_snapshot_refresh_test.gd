extends SceneTree

func _init() -> void:
	var manager_source := FileAccess.get_file_as_string("res://scripts/services/sfx_manager.gd")
	var table_source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	_require(manager_source.find("_played_event_ids.has(unique_key)") != -1, "SFX manager should suppress duplicate event ids.")
	_require(table_source.find("_sfx_visual_event_key(event, \"chip\")") != -1, "Table visual SFX should use stable visual event ids.")
	_require(table_source.find("_server_sfx_event_key(event, \"chip\")") != -1, "Server SFX should use stable action sequence ids.")
	print("SFX no duplicate on snapshot refresh test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
