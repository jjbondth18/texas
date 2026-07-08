extends SceneTree

func _init() -> void:
	var home_source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var ws_source := FileAccess.get_file_as_string("res://scripts/network/poker_ws_client.gd")
	var protocol_source := FileAccess.get_file_as_string("res://scripts/network/poker_protocol.gd")
	_require(home_source.find("_profile_ws_client.claim_daily_bonus()") != -1, "authoritative CLAIM should send claim_daily_bonus.")
	_require(ws_source.find("func claim_daily_bonus()") != -1, "websocket client should expose claim_daily_bonus.")
	_require(protocol_source.find("static func claim_daily_bonus()") != -1, "client protocol should encode claim_daily_bonus.")
	print("Daily bonus claim button authoritative test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
