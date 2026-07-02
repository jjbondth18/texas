extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(source.find("current_actor_seat") != -1)
	assert(source.find("seat_index == current_actor_seat") != -1)
	assert(source.find("border_color = HomeTheme.CYAN") != -1)
	assert(source.find("HomeTheme.PINK if is_active") != -1)
