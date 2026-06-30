extends RefCounted

func run() -> void:
	var server_source := FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	assert(server_source.find("scheduleWarmupNextHandIfNeeded") != -1)
	assert(server_source.find("setTimeout(() =>") != -1)
	assert(server_source.find("this.startNextWarmupHand(room)") != -1)
	assert(server_source.find("Next AI warm-up hand starting. Practice chips only.") != -1)
	assert(server_source.find("this.restoreWarmupStacksIfNeeded(room)") != -1)
	var db_smoke := FileAccess.get_file_as_string("res://server/src/db_smoke_test.ts")
	assert(db_smoke.find("hand-over warm-up should allow start_ai_warmup as next warm-up hand") != -1)
	assert(db_smoke.find("next warm-up hand should not change account wallet chips") != -1)
