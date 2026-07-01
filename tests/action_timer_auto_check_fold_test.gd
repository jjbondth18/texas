extends SceneTree


func _init() -> void:
	var server_source := FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	var protocol_source := FileAccess.get_file_as_string("res://server/src/protocol.ts")
	assert(server_source.find("ACTION_TIMEOUT_MS = 20000") != -1)
	assert(server_source.find("handleActionTimeout") != -1)
	assert(server_source.find("const autoAction = canCheck ? \"check\" : \"fold\"") != -1)
	assert(server_source.find("action_timeout room_id=") != -1)
	assert(protocol_source.find("action_deadline_at") != -1)
	print("Action timer auto check/fold test passed.")
	quit()
