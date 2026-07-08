extends SceneTree

func _init() -> void:
	var table_source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	var music_source := FileAccess.get_file_as_string("res://scripts/services/music_service.gd")
	_require(table_source.find("MusicServiceScript.play_table_bgm(self)") != -1, "PokerTableScreen should request table BGM in _ready.")
	_require(music_source.find("TABLE_BGM_PATH := \"res://assets/music/bgm2.ogg\"") != -1, "table BGM should use bgm2.ogg.")
	print("Table BGM plays on poker table test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
