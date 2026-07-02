extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var service_source: String = FileAccess.get_file_as_string("res://scripts/services/replay_service.gd")
	assert(source.find("_on_replay_item_gui_input") != -1)
	assert(source.find("_open_replay_detail") != -1)
	assert(source.find("ReplayServiceScript.new().load_replay_record") != -1)
	assert(service_source.find("func load_replay_record") != -1)
	assert(source.find("file_path") != -1)
