extends SceneTree


func _init() -> void:
	var launch_source := FileAccess.get_file_as_string("res://scripts/app/table_launch_context.gd")
	var session_source := FileAccess.get_file_as_string("res://scripts/data/table_session.gd")
	var table_source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	assert(launch_source.find("const DEFAULT_ACTION_TIME_SECONDS := 60") != -1)
	assert(launch_source.find("action_time_seconds = DEFAULT_ACTION_TIME_SECONDS") != -1)
	assert(session_source.find("var action_time_seconds := DEFAULT_ACTION_TIME_SECONDS") != -1)
	assert(table_source.find("\"turn_seconds\": _table_session.action_time_seconds if _table_session != null else DEFAULT_ACTION_TIME_SECONDS") != -1)
	print("Training timer 60s test passed.")
	quit()
