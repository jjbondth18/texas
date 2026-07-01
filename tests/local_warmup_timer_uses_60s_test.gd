extends SceneTree


func _init() -> void:
	var table_source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	var mock_source := FileAccess.get_file_as_string("res://scripts/demo/mock_table_simulation.gd")
	assert(table_source.find("const DEFAULT_ACTION_TIME_SECONDS := 60") != -1)
	assert(table_source.find("\"turn_seconds\": _table_session.action_time_seconds if _table_session != null else DEFAULT_ACTION_TIME_SECONDS") != -1)
	assert(mock_source.find("const DEFAULT_ACTION_TIME_SECONDS := 60") != -1)
	assert(mock_source.find("next[\"turn_seconds\"] = DEFAULT_ACTION_TIME_SECONDS") != -1)
	print("Local warm-up timer 60s test passed.")
	quit()
