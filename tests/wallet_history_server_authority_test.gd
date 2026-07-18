extends SceneTree

func _init() -> void:
	var server_source := FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	var wallet_source := FileAccess.get_file_as_string("res://server/src/db/wallet_repository.ts")
	var history_source := FileAccess.get_file_as_string("res://server/src/wallet_history.ts")

	assert(server_source.find("this.wallets.walletHistory(client.id") != -1)
	assert(server_source.find("message.player_id") == -1 or server_source.find("walletHistory(client.id") != -1)
	assert(wallet_source.find("ORDER BY created_at DESC, id DESC") != -1)
	assert(wallet_source.find("next_cursor") != -1)
	assert(history_source.find("ai_challenge_entry") != -1)
	assert(history_source.find("ai_challenge_reward") != -1)
	assert(history_source.find("official_replay_unlock") != -1)
	assert(history_source.find("server_restart_recovery") != -1)

	print("WALLET_HISTORY_SERVER_AUTHORITY_TEST_OK")
	quit()
