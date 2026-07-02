extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(source.find("ReplayTablePot") != -1)
	assert(source.find("TOTAL POT  %s") != -1)
	assert(source.find("current_bet") != -1)
	assert(source.find("Bet: %s") != -1)
	assert(source.find("pot_after") != -1)
