extends SceneTree


func _init() -> void:
	var server_source := FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	var protocol_source := FileAccess.get_file_as_string("res://server/src/protocol.ts")
	var snapshot_source := FileAccess.get_file_as_string("res://scripts/state/table_snapshot.gd")
	assert(server_source.find("DEFAULT_ACTION_TIME_SECONDS = 60") != -1)
	assert(server_source.find("ACTION_TIMEOUT_MS = DEFAULT_ACTION_TIME_SECONDS * 1000") != -1)
	assert(server_source.find("actionTimeSeconds: DEFAULT_ACTION_TIME_SECONDS") != -1)
	assert(server_source.find("action_time_seconds: room.actionTimeSeconds") != -1)
	assert(server_source.find("action_timeout_ms: this.actionTimeoutMs(room)") != -1)
	assert(protocol_source.find("action_time_seconds?: number") != -1)
	assert(snapshot_source.find("var action_time_seconds := 60") != -1)
	print("Public turn timer 60s test passed.")
	quit()
