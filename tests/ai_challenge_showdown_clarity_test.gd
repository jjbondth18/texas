extends SceneTree

func _init() -> void:
	var server_source := FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	var table_source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	var protocol_source := FileAccess.get_file_as_string("res://scripts/network/poker_protocol.gd")

	assert(server_source.find("challengeHandResultPayload") != -1)
	assert(server_source.find("ended_by_fold") != -1)
	assert(server_source.find("revealed_hole_cards") != -1)
	assert(server_source.find("hand_rank_by_seat") != -1)
	assert(server_source.find("room.challengeState = \"hand_result\"") != -1)
	assert(server_source.find("challenge_auto_next_hand") == -1)
	assert(protocol_source.find("CONTINUE_AI_CHALLENGE") != -1)
	assert(table_source.find("ChallengeNextHandButton") != -1)
	assert(table_source.find("NEXT HAND") != -1)
	assert(table_source.find("Opponent Folded") == -1, "Fold reason must come from the authoritative server payload.")
	assert(table_source.find("revealed_hole_cards") != -1)
	assert(table_source.find("Hole Cards:") != -1)
	assert(table_source.find("Best Hand:") != -1)
	assert(table_source.find("Hand Rank:") != -1)
	assert(table_source.find("Winning Hand:") != -1)
	assert(table_source.find("Challenge Reward") != -1)
	assert(table_source.find("Net Wallet Change") != -1)

	print("AI_CHALLENGE_SHOWDOWN_CLARITY_TEST_OK")
	quit()
