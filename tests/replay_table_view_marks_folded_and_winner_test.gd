extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(source.find("_replay_winner_seats") != -1)
	assert(source.find("_apply_replay_final_player_state") != -1)
	assert(source.find("status_text.to_lower().find(\"fold\")") != -1)
	assert(source.find("player_state[\"status\"] = \"winner\"") != -1)
	assert(source.find("border_color = HomeTheme.GOLD") != -1)
