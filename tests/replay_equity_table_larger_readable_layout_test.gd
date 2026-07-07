extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/replay_poker_table_screen.gd")
	assert(source.find("margin.add_theme_constant_override(\"margin_left\", 24)") != -1)
	assert(source.find("margin.add_theme_constant_override(\"margin_right\", 24)") != -1)
	assert(source.find("{\"key\": \"seat\", \"label\": \"Seat\", \"width\": 56}") != -1)
	assert(source.find("{\"key\": \"player\", \"label\": \"Player\", \"width\": 184}") != -1)
	assert(source.find("{\"key\": \"preflop\", \"label\": \"Preflop\", \"width\": 98}") != -1)
	assert(source.find("{\"key\": \"flop\", \"label\": \"Flop\", \"width\": 92}") != -1)
	assert(source.find("{\"key\": \"final\", \"label\": \"Final\", \"width\": 96}") != -1)
	assert(source.find("cell.custom_minimum_size = Vector2(width, 25 if not is_header else 27)") != -1)
	assert(source.find("HomeTheme.make_font_settings(label, 11 if not is_header else 12") != -1)
	assert(source.find("scroll.custom_minimum_size = Vector2(736, 132)") != -1)
	assert(source.find("vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO") != -1)
