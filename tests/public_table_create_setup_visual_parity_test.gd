extends SceneTree

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	_require(source.contains("CREATE PUBLIC TABLE"), "Public setup must title as CREATE PUBLIC TABLE")
	_require(source.contains("_add_table_setup_mode_switch(column, public_table, selected_mode)"), "Public setup must use the shared tab row")
	_require(source.contains("_add_table_setup_profile_row(column)"), "Public setup must use the shared player info row")
	_require(source.contains("Create a public chip table with your selected stakes."), "Public setup must use Quick-style subtitle")
	_require(source.contains("Gem public tables require secure server matchmaking."), "Public Gem must show secure matchmaking copy")
	_require(source.contains("var gem_disabled: bool = public_table"), "Public Gem tab must be visible but disabled")
	_require(source.contains("confirm.text = \"COMING SOON\" if gem_selected else (\"CREATE TABLE\""), "Public setup must use shared footer button logic")
	print("Public table create setup visual parity test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
