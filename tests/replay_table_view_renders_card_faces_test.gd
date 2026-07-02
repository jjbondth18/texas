extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(source.find("ReplayCardViewScene") != -1)
	assert(source.find("res://scenes/components/card_view.tscn") != -1)
	assert(source.find("_add_replay_card_views") != -1)
	assert(source.find("_replay_card_data") != -1)
	assert(source.find("\"face_up\": true") != -1)
	assert(source.find("ReplayTableBoardCards") != -1)
	assert(source.find("ReplaySeatHoleCards") != -1)
