extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/replay_poker_table_screen.gd")
	assert(source.find("_hide_table_room_info_children([\"Seat\", \"ACTION TIMER\"])") != -1)
	assert(source.find("label == _replay_info_action_label") != -1)
	assert(source.find("ProgressBar") != -1)
	assert(source.find("set_action_timer(0, 1, false, false)") != -1)
	assert(source.find("ACTION TIMER") != -1)
	assert(source.find("Seat: -1") == -1)
