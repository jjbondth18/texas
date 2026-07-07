extends RefCounted

func run() -> void:
	var profile_source: String = FileAccess.get_file_as_string("res://scripts/services/profile_service.gd")
	var home_source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(profile_source.find("func unlock_replay") != -1)
	assert(profile_source.find("available_gems < cost_gems") != -1)
	assert(profile_source.find("\"not_enough_gems\"") != -1)
	assert(home_source.find("Not enough gems.\\nVisit Store to get more gems.") != -1)
