extends SceneTree

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	_require(source.find("func _play_currency_sfx(currency: String, event_id: String)") != -1, "Home should route currency SFX through a helper.")
	_require(source.find("SfxManagerScript.play_gem(self, event_id)") != -1, "Gem currency events should play gem SFX.")
	_require(source.find("mock_purchase:server:%s:%d") != -1, "Server mock gem purchases should use a stable SFX key.")
	print("SFX gem on mock gem purchase test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
