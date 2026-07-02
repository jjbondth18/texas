extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/replay_poker_table_screen.gd")
	assert(source.find("_configure_replay_info_panel") != -1)
	assert(source.find("ReplayCurrentActionLabel") != -1)
	assert(source.find("_replay_display_status") != -1)
	assert(source.find("\"ready\": false") != -1)
	assert(source.find("ControlZone/MainButtons") != -1)
	assert(source.find("ControlZone/RaiseControlPanel") != -1)
	assert(source.find("REPLAY CONTROLS") != -1)
	assert(source.find("FOLD") == -1)
	assert(source.find("CALL") == -1)
	assert(source.find("RAISE") == -1)
