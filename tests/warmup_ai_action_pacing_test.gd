extends RefCounted

func run() -> void:
	var betting_source := FileAccess.get_file_as_string("res://server/src/betting_engine.ts")
	assert(betting_source.find("export function processSingleAutomaticTurn") != -1)
	assert(betting_source.find("processSingleAutomaticTurn(table, false)") != -1)
	assert(betting_source.find("includeWarmupAi && seat.warmupAi") != -1)
	var server_source := FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	assert(server_source.find("warmupAiActionTimer") != -1)
	assert(server_source.find("scheduleWarmupAiActionIfNeeded") != -1)
	assert(server_source.find("processSingleAutomaticTurn(room.table, true)") != -1)
	assert(server_source.find("this.broadcast(room)") != -1)
	assert(server_source.find("if (!this.isWarmupAiTurn(room))") != -1)
	assert(server_source.find("this.cancelWarmupAiAction(room)") != -1)
	var db_smoke := FileAccess.get_file_as_string("res://server/src/db_smoke_test.ts")
	assert(db_smoke.find("start_ai_warmup should not synchronously run a complete hand") != -1)
	assert(db_smoke.find("start_ai_warmup should broadcast a concrete current turn before AI acts") != -1)
