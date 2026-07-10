extends SceneTree
var _failures: Array[String] = []

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/network/poker_ws_client.gd")
	_require(source.find("message.get(\"profile_snapshot\", {})") != -1, "client should read profile_snapshot")
	_require(source.find("server_snapshot if not server_snapshot.is_empty()") != -1, "profile_snapshot should have priority")
	_require(source.find("message.get(\"profile\", {})") != -1, "legacy profile fallback should remain")
	_require(source.find("message.get(\"wallet\", {})") != -1, "legacy wallet fallback should remain")
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
