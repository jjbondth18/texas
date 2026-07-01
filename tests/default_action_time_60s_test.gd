extends SceneTree


func _init() -> void:
	var server_source := FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	var table_source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	var launch_source := FileAccess.get_file_as_string("res://scripts/app/table_launch_context.gd")
	var session_source := FileAccess.get_file_as_string("res://scripts/data/table_session.gd")
	var registry_source := FileAccess.get_file_as_string("res://scripts/services/public_table_registry.gd")
	assert(server_source.find("DEFAULT_ACTION_TIME_SECONDS = 60") != -1)
	assert(table_source.find("const DEFAULT_ACTION_TIME_SECONDS := 60") != -1)
	assert(launch_source.find("const DEFAULT_ACTION_TIME_SECONDS := 60") != -1)
	assert(session_source.find("const DEFAULT_ACTION_TIME_SECONDS := 60") != -1)
	assert(registry_source.find("const DEFAULT_ACTION_TIME_SECONDS := 60") != -1)
	assert(table_source.find("turn_seconds\": 15") == -1)
	assert(table_source.find("15000") == -1)
	assert(server_source.find("ACTION_TIMEOUT_MS = 20000") == -1)
	print("Default action time 60s test passed.")
	quit()
