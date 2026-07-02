extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(source.find("viewer_order") != -1)
	assert(source.find("posts small blind") != -1)
	assert(source.find("posts big blind") != -1)
	assert(source.find("calls %s") != -1)
	assert(source.find("checks") != -1)
	assert(source.find("folds") != -1)
	assert(source.find("raises to") != -1)
	assert(source.find("goes all-in") != -1)
