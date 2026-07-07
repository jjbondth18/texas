extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/replay_poker_table_screen.gd")
	assert(source.find("{\"key\": \"player\", \"label\": \"Player\", \"width\": 168}") != -1)
	assert(source.find("{\"key\": \"preflop\", \"label\": \"Preflop\", \"width\": 94}") != -1)
	assert(source.find("{\"key\": \"final\", \"label\": \"Final\", \"width\": 94}") != -1)
	assert(source.find("cell.custom_minimum_size = Vector2(width, 25 if not is_header else 27)") != -1)
	assert(source.find("HomeTheme.make_font_settings(label, 11 if not is_header else 12") != -1)
	assert(source.find("scroll.custom_minimum_size = Vector2(730, 132)") != -1)
	assert(source.find("vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO") != -1)
