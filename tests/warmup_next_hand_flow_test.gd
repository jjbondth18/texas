extends RefCounted

func run() -> void:
	var server_source := FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	assert(server_source.find("host_started_local_warmup accepted") != -1)
	assert(server_source.find("room.hostInLocalWarmup = client.id") != -1)
	assert(server_source.find("real_player_joined_interrupts_local_warmup") != -1)
	var db_smoke := FileAccess.get_file_as_string("res://server/src/db_smoke_test.ts")
	assert(db_smoke.find("server room should remain waiting while host runs local warm-up") != -1)
	assert(db_smoke.find("real public room should remain AI-free after join") != -1)
