extends SceneTree


func _init() -> void:
	var poker_source: String = FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	_require(poker_source.find("deduct_table_buy_in_currency") != -1, "Play Again must use currency-aware buy-in deduction.")
	_require(poker_source.find("_can_play_again") != -1 and poker_source.find("profile.get(\"gems\"") != -1, "Play Again affordability must check Gems for Gem tables.")
	print("Gem table Play Again no double charge test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
