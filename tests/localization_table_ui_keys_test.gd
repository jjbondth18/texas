extends SceneTree

func _init() -> void:
	var table_source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	var action_source := FileAccess.get_file_as_string("res://scripts/components/action_bar.gd")
	var info_source := FileAccess.get_file_as_string("res://scripts/components/table_room_info_panel.gd")
	_require(action_source.find("table.fold") != -1, "ActionBar fold should use localization.")
	_require(action_source.find("table.bet_amount") != -1, "ActionBar bet amount should use localization.")
	_require(table_source.find("_t(\"table.exit_table\")") != -1, "Poker table exit button should use localization.")
	_require(table_source.find("_t(\"table.waiting_for_players\")") != -1, "Poker table waiting title should use localization.")
	_require(info_source.find("table.action_timer") != -1, "Table info action timer should use localization.")
	print("Localization table UI keys test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
