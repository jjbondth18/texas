extends SceneTree
var _failures: Array[String] = []

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/network/poker_ws_client.gd")
	_require(source.find("message.get(\"profile_snapshot\", {})") != -1, "client should read profile_snapshot")
	_require(source.find("server_snapshot if not server_snapshot.is_empty()") != -1, "profile_snapshot should have priority")
	_require(source.find("PokerProtocolScript.PROFILE_SNAPSHOT") != -1, "client should handle standalone profile_snapshot messages")
	_require(source.find("PokerProtocolScript.DAILY_BONUS_RESULT") != -1 and source.find("_emit_profile_payload(message)") != -1, "daily bonus responses should emit profile payloads")
	_require(source.find("message.get(\"profile\", {})") != -1, "legacy profile fallback should remain")
	_require(source.find("message.get(\"wallet\", {})") != -1, "legacy wallet fallback should remain")
	_require(source.find("message.has(\"is_new_player\")") != -1, "client should pass through top-level is_new_player")
	var home_source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var table_source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	_require(home_source.find("profile_synced.connect(_on_profile_server_profile_synced)") != -1, "home should apply profile_snapshot signals")
	_require(home_source.find("_maybe_show_new_player_welcome(profile)") != -1, "home should check server new-player flag after profile sync")
	_require(home_source.find("_welcome_shown_for_player_id") != -1, "home should suppress duplicate welcome toasts")
	_require(home_source.find("is_new_player") != -1, "home welcome should use server is_new_player flag")
	_require(table_source.find("profile_synced.connect(_on_server_profile_synced)") != -1, "table should apply realtime profile_snapshot signals")
	_require(table_source.find("apply_server_profile_snapshot({}, {}, [], true)") == -1, "table daily bonus handler should not locally add XP after server snapshots")
	_finish("Poker WS profile snapshot priority test passed.")

func _require(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish(success_message: String) -> void:
	if _failures.is_empty():
		print(success_message)
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
