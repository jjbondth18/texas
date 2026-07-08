extends SceneTree


func _init() -> void:
	var record_source: String = FileAccess.get_file_as_string("res://scripts/replay/hand_replay_record.gd")
	var repo_source: String = FileAccess.get_file_as_string("res://scripts/replay/replay_repository.gd")
	var home_source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	_require(record_source.find("\"currency\"") != -1, "Replay records must carry currency.")
	_require(repo_source.find("\"currency\": currency") != -1, "Replay index must carry currency.")
	_require(home_source.find("_currency_label(currency)") != -1, "Replay list profit label must use Chips/Gems unit.")
	print("Gem table replay profit unit test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
