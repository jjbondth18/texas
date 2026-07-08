extends SceneTree

func _init() -> void:
	var home_source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var table_source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	_require(home_source.find("\"training\"") != -1, "Home should expose Training entry.")
	_require(table_source.find("MusicServiceScript.play_table_bgm(self)") != -1, "Training enters PokerTableScreen and should use table BGM.")
	print("Table BGM plays on training test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
