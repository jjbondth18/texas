extends RefCounted

func run() -> void:
	var table_source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	assert(table_source.find("_schedule_next_hand_after_result(_hand_result_hold_seconds)") != -1)
	assert(table_source.find("if _table_session != null and _table_session.can_start_next_hand():\n\t\t_start_next_hand()") != -1)
	assert(table_source.find("Practice chips only") != -1)
	var session_source := FileAccess.get_file_as_string("res://scripts/data/table_session.gd")
	assert(session_source.find("uses_practice_chips = bool(context.get(\"uses_practice_chips\", mode == MODE_TRAINING))") != -1)
	assert(session_source.find("affects_account_balance = bool(context.get(\"affects_account_balance\", mode != MODE_TRAINING))") != -1)
	var isolation_test := FileAccess.get_file_as_string("res://tests/training_session_result_isolation_test.gd")
	assert(isolation_test.find("training must not change chip balance") != -1)
	assert(isolation_test.find("training must not change gem balance") != -1)
