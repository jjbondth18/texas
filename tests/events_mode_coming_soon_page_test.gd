extends SceneTree

func _init() -> void:
	var home_source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(home_source.find("func _build_events_panel") != -1)
	assert(home_source.find("ALL-IN SURVIVAL") != -1)
	assert(home_source.find("LUCKY SPIN TABLE") != -1)
	assert(home_source.find("WEEKEND GEM CUP") != -1)
	assert(home_source.find("COMING SOON") != -1)
	print("Events mode Coming Soon page test passed.")
	quit()
