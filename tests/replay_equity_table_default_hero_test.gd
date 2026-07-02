extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/replay/replay_equity_table.gd")
	assert(source.find("_resolve_hero_seat") != -1)
	assert(source.find("is_local") != -1)
	assert(source.find("_player_for_seat(players, 5)") != -1)
	assert(source.find("not bool(player.get(\"is_ai\", false))") != -1)
	assert(source.find("Dictionary(players[0])") != -1)
