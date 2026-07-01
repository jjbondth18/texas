extends SceneTree


func _init() -> void:
	var identity_source: String = FileAccess.get_file_as_string("res://scripts/services/identity_service.gd")
	assert(identity_source.find("ARG_DEV_PLAYER_ID := \"dev-player-id\"") != -1)
	assert(identity_source.find("ARG_DEV_PLAYER_NAME := \"dev-player-name\"") != -1)
	assert(identity_source.find("ARG_DEV_SAVE_SUFFIX := \"dev-save-suffix\"") != -1)
	assert(identity_source.find("ENV_DEV_PLAYER_ID := \"TEXAS_DEV_PLAYER_ID\"") != -1)
	assert(identity_source.find("ENV_DEV_PLAYER_NAME := \"TEXAS_DEV_PLAYER_NAME\"") != -1)
	assert(identity_source.find("ENV_DEV_SAVE_SUFFIX := \"TEXAS_DEV_SAVE_SUFFIX\"") != -1)
	assert(identity_source.find("func apply_dev_overrides_to_profile") != -1)
	assert(identity_source.find("\"external_id\": local_player_id") != -1)
	print("Dev identity override test passed.")
	quit()
