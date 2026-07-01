extends RefCounted


func _init() -> void:
	var table_source: String = FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	var board_source: String = FileAccess.get_file_as_string("res://scripts/components/community_board.gd")

	assert(board_source.find("func get_deal_reveal_center_global() -> Vector2:") != -1)
	assert(board_source.find("return get_global_rect().get_center()") != -1)
	assert(table_source.find("const COMMUNITY_FLYING_CARD_BACK_PATH := \"res://assets/ui/cardback/asset_01.png\"") != -1)
	assert(table_source.find("card.texture = _load_texture(COMMUNITY_FLYING_CARD_BACK_PATH)") != -1)
	assert(table_source.find("var target_position: Vector2 = _community_deal_target_point() - card_size * 0.5") != -1)
	assert(table_source.find("func _community_deal_target_point() -> Vector2:") != -1)
	assert(table_source.find("board.get_deal_reveal_center_global()") != -1)
	assert(table_source.find("get_card_slot_global_center") == -1)
	assert(table_source.find("func _community_card_point") == -1)
