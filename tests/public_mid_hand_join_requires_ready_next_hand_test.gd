extends SceneTree

func _init() -> void:
	var table_state_source: String = FileAccess.get_file_as_string("res://server/src/table_state.ts")
	var db_smoke_source: String = FileAccess.get_file_as_string("res://server/src/db_smoke_test.ts")

	_require(table_state_source.find("status: (joinsNextHand ? \"waiting_next_hand\" : \"sitting\")") != -1, "Mid-hand joiner must wait next hand.")
	_require(table_state_source.find("(!requireReady || seat.ready)") != -1, "Next hand eligibility must require ready.")
	_require(db_smoke_source.find("mid-hand unready joiner should not block ready players from continuing") != -1, "DB smoke should cover unready next-hand joiner not blocking ready players.")
	_require(db_smoke_source.find("mid-hand joiner should be marked ready for the next hand without joining current hand") != -1, "DB smoke should cover ready next hand joiner.")
	print("Public mid-hand join requires ready next hand test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
