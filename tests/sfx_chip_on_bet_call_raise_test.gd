extends SceneTree

func _init() -> void:
	var table_source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	_require(table_source.find("\"small_blind\", \"big_blind\", \"call\", \"bet\", \"raise\", \"all_in\"") != -1, "Chip SFX actions should include blinds/call/bet/raise/all-in.")
	_require(table_source.find("SfxManagerScript.play_chip(self, _server_sfx_event_key(event, \"chip\"))") != -1, "Authoritative chip actions should play chip SFX.")
	_require(table_source.find("SfxManagerScript.play_chip(self, _sfx_visual_event_key(event, \"chip\"))") != -1, "Visual chip movement should play chip SFX.")
	print("SFX chip on bet call raise test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
