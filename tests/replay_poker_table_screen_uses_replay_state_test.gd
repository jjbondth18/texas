extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/replay_poker_table_screen.gd")
	assert(source.find("func render_replay_state") != -1)
	assert(source.find("_render_seats(players, current_actor_seat)") != -1)
	assert(source.find("_community_board.set_cards") != -1)
	assert(source.find("_pot_display.set_pot") != -1)
	assert(source.find("_status_panel.set_status") != -1)
	assert(source.find("_action_bar.set_local_player_info") != -1)
