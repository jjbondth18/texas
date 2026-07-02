extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(source.find("ReplayFullscreenOverlay") != -1)
	assert(source.find("_show_replay_fullscreen_overlay") != -1)
	assert(source.find("_ensure_replay_fullscreen_overlay") != -1)
	assert(source.find("Control.PRESET_FULL_RECT") != -1)
	assert(source.find("_replay_fullscreen_overlay.z_index = 500") != -1)
