extends SceneTree

func _init() -> void:
	var table_state_source := FileAccess.get_file_as_string("res://server/src/table_state.ts")
	var db_smoke_source := FileAccess.get_file_as_string("res://server/src/db_smoke_test.ts")

	assert(table_state_source.find("[\"ready\", \"sitting\", \"waiting_next_hand\"].includes(seat.status)") != -1)
	assert(table_state_source.find("if (eligible.includes(seat)) seat.status = \"playing\"") != -1)
	assert(db_smoke_source.find("waiting_next_hand") != -1)
	assert(db_smoke_source.find("mid-hand joiner should wait for next hand") != -1)
	assert(db_smoke_source.find("mid-hand joiner should receive cards on the next hand") != -1)
	quit()
