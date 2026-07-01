extends RefCounted

func run() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	assert(source.find("server_real_player_count") != -1)
	assert(source.find("can_show_ai_warmup_button") != -1)
	assert(source.find("_should_show_public_warmup_entry()") != -1)
	assert(source.find("waiting_for_real_players := local_seat_confirmed and room_state in [\"waiting\", \"waiting_for_players\"] and real_count < 2") != -1)
	assert(source.find("return _real_public_player_count_from_flow() == 1") != -1)
