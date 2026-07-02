extends RefCounted

func run() -> void:
	var server_source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	var protocol_source: String = FileAccess.get_file_as_string("res://server/src/protocol.ts")
	var table_source: String = FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	assert(server_source.find("buildHandReplayRecord") != -1)
	assert(protocol_source.find("replay_record?: Record<string, unknown>") != -1)
	assert(table_source.find("_save_server_replay_record_if_present") != -1)
	assert(table_source.find("HandReplayRecordScript.from_server_payload") != -1)
