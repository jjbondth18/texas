extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/replay_poker_table_screen.gd")
	assert(source.find("_equity_table_panel.size = Vector2(740, 368)") != -1)
	assert(source.find("margin.add_theme_constant_override(\"margin_left\", 22)") != -1)
	assert(source.find("margin.add_theme_constant_override(\"margin_right\", 22)") != -1)
	assert(source.find("{\"key\": \"seat\", \"label\": \"Seat\", \"width\": 48}") != -1)
	assert(source.find("{\"key\": \"player\", \"label\": \"Player\", \"width\": 126}") != -1)
	assert(source.find("{\"key\": \"preflop\", \"label\": \"Preflop\", \"width\": 84}") != -1)
	assert(source.find("{\"key\": \"flop\", \"label\": \"Flop\", \"width\": 78}") != -1)
	assert(source.find("{\"key\": \"final\", \"label\": \"Final\", \"width\": 82}") != -1)
	assert(source.find("cell.custom_minimum_size = Vector2(width, 28 if not is_header else 30)") != -1)
	assert(source.find("HomeTheme.make_font_settings(label, 12 if not is_header else 13") != -1)
	assert(source.find("scroll.custom_minimum_size = Vector2(696, 132)") != -1)
	assert(source.find("vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO") != -1)
	assert(source.find("return name.substr(0, 10) + \"...\" if name.length() > 13 else name") != -1)
