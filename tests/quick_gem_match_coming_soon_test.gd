extends SceneTree


func _init() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	_require(source.find("GEM MATCH") != -1, "Quick setup must keep Gem Match tab.")
	_require(source.find("_quick_start_button.text = \"FIND TABLE\" if is_chip_mode else \"COMING SOON\"") != -1, "Gem Match action must remain Coming Soon.")
	_require(source.find("if _quick_play_mode != \"chip\":\n\t\treturn") != -1, "Gem Match must not create or join a table.")
	print("Quick Gem Match coming soon test passed.")
	quit()


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
