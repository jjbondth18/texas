extends SceneTree


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	_require(source.find("_top_bar.exit_requested.connect(_request_exit_game)") != -1, "Home Exit must open the shared confirmation flow.")
	_require(source.find("_request_exit_game()") != -1 and source.find("EXIT GAME?") != -1, "Home Escape must request Exit Game confirmation.")
	_require(source.find("_request_exit_replay(false)") != -1 and source.find("EXIT REPLAY?") != -1, "Replay Escape must request Exit Replay confirmation.")
	_require(source.find("back_to_detail_requested\", Callable(self, \"_request_exit_replay\").bind(false)") != -1, "Back to Detail must pass through confirmation.")
	_require(source.find("back_to_replays_requested\", Callable(self, \"_request_exit_replay\").bind(true)") != -1, "Back to Replays must pass through confirmation.")
	_require(source.find("Replay unlock access and your wallet will not be changed.") != -1, "Replay exit copy must preserve entitlement and wallet expectations.")
	print("Home and replay exit confirmation test passed.")
	quit()


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
