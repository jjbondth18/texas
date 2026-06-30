extends RefCounted

func run() -> void:
	var server_source := FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	assert(server_source.find("markHostStartedLocalWarmup") != -1)
	assert(server_source.find("room.hostInLocalWarmup = client.id") != -1)
	assert(server_source.find("is_ai_warmup: false") != -1)
	assert(server_source.find("local_warmup: true") != -1)
	var db_smoke := FileAccess.get_file_as_string("res://server/src/db_smoke_test.ts")
	assert(db_smoke.find("start_ai_warmup should not add AI seats to server public room") != -1)
	assert(db_smoke.find("local warm-up should not change server public current_players") != -1)
