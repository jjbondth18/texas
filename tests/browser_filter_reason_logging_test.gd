extends SceneTree


func _init() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	_require(source.find("func _room_browser_filter_decision") != -1, "Browser filter must expose include/reason decisions.")
	_require(source.find("[ClientTableList] raw server list count=") != -1, "Browser refresh must print raw/normalized/filtered counts.")
	_require(source.find("browser_include=%s") != -1, "Browser diagnostics must print browser include.")
	_require(source.find("quick_candidate=%s") != -1, "Browser diagnostics must print quick candidate.")
	_require(source.find("host_warmup_joinable") != -1, "Browser filter must include host warm-up rooms with a reason.")
	print("Browser filter reason logging test passed.")
	quit()


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
