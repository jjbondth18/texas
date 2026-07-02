extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/replay_poker_table_screen.gd")
	assert(source.find("action_pressed.connect") == -1)
	assert(source.find("_on_action_pressed") == -1)
	assert(source.find("sit_down") == -1)
	assert(source.find("ready_requested") == -1)
	assert(source.find("start_ai_warmup") == -1)
	assert(source.find("Add Chips") == -1)
	assert(source.find("BACK TO DETAIL") != -1)
	assert(source.find("BACK TO REPLAYS") != -1)
	assert(source.find("PREV") != -1)
	assert(source.find("NEXT") != -1)
