extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/replay/replay_equity_table.gd")
	var screen_source: String = FileAccess.get_file_as_string("res://scripts/screens/replay_poker_table_screen.gd")
	assert(source.find("_perceived_rows(record, players)") != -1)
	assert(source.find("_perceived_player_equity_label(record, players") != -1)
	assert(screen_source.find("Perceived - each player knows only their own cards.") != -1)
	assert(screen_source.find("player-view estimate for") == -1)
