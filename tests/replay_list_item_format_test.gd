extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(source.find("_replay_list_title") != -1)
	assert(source.find("_replay_list_stakes_line") != -1)
	assert(source.find("_replay_list_result_line") != -1)
	assert(source.find("_replay_list_time_label") != -1)
	assert(source.find("Hand %s (%s)") == -1)
	assert(source.find("item_summary.text = str(hand.get(\"table_name\", \"\"))") == -1)
	assert(source.find("Winner: %s - Pot %s") != -1)
	assert(source.find("NLH %s") != -1)
