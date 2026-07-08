extends SceneTree


func _init() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	_require(source.find("GEM MATCH") != -1, "Quick setup must keep Gem Match tab.")
	_require(source.find("\"table_type\": table_type") != -1, "Quick Gem must send a table_type through the table config.")
	_require(source.find("\"currency\": currency") != -1, "Quick Gem must send currency through the table config.")
	_require(source.find("Not enough gems. Visit Store to get more gems.") != -1, "Quick Gem must block insufficient gem wallet before entering a table.")
	print("Quick Gem Match enabled test passed.")
	quit()


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
