extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(source.find("summary_panel") == -1)
	assert(source.find("summary_grid") == -1)
	assert(source.find("MODE    ROOM") == -1)
	assert(source.find("_add_replay_metric(summary_grid") == -1)
