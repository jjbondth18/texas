extends SceneTree


func _init() -> void:
	var home_source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var server_source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	_require(home_source.find("Not enough gems. Visit Store to get more gems.") != -1, "Quick Gem UI must show insufficient gems copy.")
	_require(home_source.find("_can_afford_buy_in_for_currency(_selected_quick_buy_in, currency)") != -1, "Quick Gem must check the selected currency wallet before launch.")
	_require(server_source.find("if (currency !== \"gems\") return;") != -1, "Server should early-reject insufficient gem quick/private joins without changing chip quick behavior.")
	_require(server_source.find("throw new Error(currency === \"gems\" ? \"insufficient_gems\" : \"insufficient_chips\")") != -1, "Server must return insufficient_gems for gem table affordability failures.")
	print("Quick Gem insufficient gems test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
