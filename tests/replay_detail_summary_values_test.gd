extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(source.find("_replay_blinds_label") != -1)
	assert(source.find("_replay_hand_label") != -1)
	assert(source.find("_replay_result_label") != -1)
	assert(source.find("_replay_profit_label") != -1)
	assert(source.find("_replay_final_pot_label") != -1)
	assert(source.find("_add_replay_metric(summary_grid, \"Winner\", _winner_summary(results, players))") != -1)
	assert(source.find("Room Code %s") != -1)
