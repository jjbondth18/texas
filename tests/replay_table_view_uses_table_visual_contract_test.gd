extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(source.find("REPLAY_TABLE_BACKGROUND") != -1)
	assert(source.find("res://assets/poker_table/backgrounds/table_neon_v1.png") != -1)
	assert(source.find("ReplayTableBackground") != -1)
	assert(source.find("ReplayTableVisualOverlay") != -1)
	assert(source.find("REPLAY_CHIP_STACK") != -1)
	assert(source.find("REPLAY_AVATAR_RING") != -1)
