extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(source.find("_replay_panel.visible = false") != -1)
	assert(source.find("_center_brand.visible = false") != -1)
	assert(source.find("_prompt.visible = false") != -1)
	assert(source.find("_hide_replay_fullscreen_overlay") != -1)
	assert(source.find("_replay_panel.visible = true") != -1)
