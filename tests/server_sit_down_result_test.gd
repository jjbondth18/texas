extends RefCounted

func run() -> void:
	var protocol_source := FileAccess.get_file_as_string("res://server/src/protocol.ts")
	var room_source := FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	var db_smoke_source := FileAccess.get_file_as_string("res://server/src/db_smoke_test.ts")
	assert(protocol_source.find("\"sit_down_result\"") != -1)
	assert(room_source.find("type: \"sit_down_result\"") != -1)
	assert(room_source.find("ok: true") != -1)
	assert(room_source.find("ok: false") != -1)
	assert(db_smoke_source.find("sit_down should return sit_down_result ok=true") != -1)
