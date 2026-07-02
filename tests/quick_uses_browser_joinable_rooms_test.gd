extends SceneTree


func _init() -> void:
	var home_source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var server_source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	_require(home_source.find("var browser_decision: Dictionary = _room_browser_filter_decision(room)") != -1, "Client Quick diagnostics must build from Browser joinable decisions.")
	_require(home_source.find("func _quick_table_filter_decision") != -1, "Client Quick must have a config filter layered over Browser rooms.")
	_require(server_source.find("const listDecision = this.publicRoomListDecision(room);") != -1, "Server Quick must reuse public room list decision.")
	_require(server_source.find("private publicRoomListDecision") != -1, "Server must expose a single public room list decision.")
	print("Quick uses browser joinable rooms test passed.")
	quit()


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
