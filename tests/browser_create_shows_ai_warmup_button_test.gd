extends RefCounted

func run() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	assert(source.find("PublicWaitingPanel") != -1)
	assert(source.find("START AI WARM-UP") != -1)
	assert(source.find("_should_show_public_warmup_entry") != -1)
	assert(source.find("_has_local_public_seat") != -1)
	assert(source.find("_real_public_player_count_from_flow() == 1") != -1)
	assert(source.find("Warm-up uses practice chips and does not affect your wallet.") != -1)
