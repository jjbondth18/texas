extends SceneTree

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/services/sfx_manager.gd")
	_require(source.find("DRAW_CARD_PATH := \"res://assets/music/draw.wav\"") != -1, "draw.wav should be registered.")
	_require(source.find("SHUFFLE_PATH := \"res://assets/music/shuffle.wav\"") != -1, "shuffle.wav should be registered.")
	_require(source.find("CHIP_PATH := \"res://assets/music/chip.wav\"") != -1, "chip.wav should be registered.")
	_require(source.find("GEM_PATH := \"res://assets/music/Gem.wav\"") != -1, "Gem.wav should be registered with the actual asset name.")
	_require(source.find("WIN_PATH := \"res://assets/music/chip_gem_win.wav\"") != -1, "chip_gem_win.wav should be registered.")
	print("SFX manager loads assets test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
