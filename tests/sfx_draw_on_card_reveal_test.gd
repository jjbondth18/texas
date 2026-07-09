extends SceneTree

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	_require(source.find("play_draw_card(self, _sfx_visual_event_key(event, \"draw\"))") == -1, "Hole-card deal events should not stack draw SFX at hand start.")
	_require(source.find("play_draw_card(self, \"%s:community:%d\"") != -1, "Community card reveal should play draw SFX.")
	print("SFX draw on card reveal test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
