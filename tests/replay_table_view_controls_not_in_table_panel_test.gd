extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(source.find("ReplayFullscreenControls") != -1)
	assert(source.find("controls.anchor_top = 0.90") != -1)
	assert(source.find("controls.alignment = BoxContainer.ALIGNMENT_CENTER") != -1)
	assert(source.find("BACK TO DETAIL") != -1)
	assert(source.find("BACK TO REPLAYS") != -1)
