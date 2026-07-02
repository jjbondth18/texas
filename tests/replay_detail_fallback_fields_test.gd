extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(source.find("No actions recorded.") != -1)
	assert(source.find("No board cards recorded.") != -1)
	assert(source.find("No results recorded.") != -1)
	assert(source.find("Unknown") != -1)
	assert(source.find("return \"-\"") != -1)
