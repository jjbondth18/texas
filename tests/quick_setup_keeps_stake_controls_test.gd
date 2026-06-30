extends SceneTree

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	_require(source.contains("_build_quick_setup_section(_quick_chip_settings_container, \"BUY-IN\""), "Quick setup must keep Buy-in controls")
	_require(source.contains("_build_quick_blinds_section(_quick_chip_settings_container)"), "Quick setup must keep Blinds controls")
	_require(source.contains("_build_quick_setup_section(_quick_chip_settings_container, \"HAND COUNT\""), "Quick setup must keep Hand Count controls")
	_require(source.contains("\"buy_in\": _selected_quick_buy_in"), "Quick Chip must use selected buy-in")
	_require(source.contains("\"small_blind\": _selected_quick_small_blind"), "Quick Chip must use selected small blind")
	_require(source.contains("\"big_blind\": _selected_quick_big_blind"), "Quick Chip must use selected big blind")
	_require(source.contains("\"max_hands\": _selected_quick_max_hands"), "Quick Chip must use selected hand count")
	_require(source.contains("_quick_start_button.text = \"FIND TABLE\""), "Quick Chip button must read FIND TABLE")
	_require(source.contains("if _quick_play_mode != \"chip\":\n\t\treturn"), "Quick Gem must not enter a table")
	print("Quick setup keeps stake controls test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
