extends SceneTree

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	_require(source.contains("CHIP TABLE"), "Quick Play must keep Chip Table entry")
	_require(source.contains("GEM MATCH"), "Quick Play must keep Gem Match entry")
	_require(source.contains("Quickly join an available public chip table with your selected stakes."), "Quick Chip must describe selected stakes")
	_require(source.contains("quick_join_public_table(_player_profile, setup_config)"), "Quick Chip must call quick_join_public_table with default config")
	_require(source.contains("_build_quick_setup_section(_quick_chip_settings_container, \"BUY-IN\""), "Quick Play panel must build Buy-in choices")
	_require(source.contains("_build_quick_blinds_section(_quick_chip_settings_container)"), "Quick Play panel must build Blinds choices")
	_require(source.contains("_build_quick_setup_section(_quick_chip_settings_container, \"HAND COUNT\""), "Quick Play panel must build Hand Count choices")
	_require(source.contains("\"buy_in\": _selected_quick_buy_in"), "Quick Chip must use selected buy-in")
	_require(source.contains("\"small_blind\": _selected_quick_small_blind"), "Quick Chip must use selected blinds")
	_require(source.contains("\"max_hands\": _selected_quick_max_hands"), "Quick Chip must use selected hand count")
	_require(source.contains("if _quick_play_mode != \"chip\":\n\t\treturn"), "Quick Gem must not enter a table")
	print("Quick play simple entry test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
