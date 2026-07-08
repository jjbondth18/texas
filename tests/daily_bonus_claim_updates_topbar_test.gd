extends SceneTree

func _init() -> void:
	var home_source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var client_source := FileAccess.get_file_as_string("res://scripts/network/poker_ws_client.gd")
	_require(client_source.find("[DailyBonusClient] claim response success=") != -1, "client should log claim responses for diagnostics.")
	_require(home_source.find("func _on_profile_server_daily_login_awarded") != -1, "home should handle successful server daily bonus claims.")
	_require(home_source.find("_refresh_profile_views_from_server()") != -1, "successful daily claim should refresh topbar/profile/daily UI.")
	_require(home_source.find("[DailyBonusClient] topbar updated chips=") != -1, "home should log refreshed topbar wallet values.")
	print("Daily bonus claim updates topbar test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
