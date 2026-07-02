extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/replay_poker_table_screen.gd")
	assert(source.find("_replay_display_status") != -1)
	assert(source.find("NOT READY") == -1)
	assert(source.find("\"not_ready\"") == -1)
	assert(source.find("\"ready\"") == -1 or source.find("\"ready\": false") != -1)
	assert(source.find("return \"winner\"") != -1)
	assert(source.find("return \"folded\"") != -1)
	assert(source.find("return \"showdown\"") != -1)
	assert(source.find("return \"active\"") != -1)
