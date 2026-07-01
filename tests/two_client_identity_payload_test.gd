extends SceneTree


func _init() -> void:
	var ws_source: String = FileAccess.get_file_as_string("res://scripts/network/poker_ws_client.gd")
	var protocol_source: String = FileAccess.get_file_as_string("res://scripts/network/poker_protocol.gd")
	var server_source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	assert(ws_source.find("IdentityServiceScript.new().get_identity(profile_hint)") != -1)
	assert(ws_source.find("var has_dev_override: bool") != -1)
	assert(ws_source.find("var compatible_player_id: String = resolved_external_id if has_dev_override") != -1)
	assert(protocol_source.find("data[\"external_id\"] = external_id") != -1)
	assert(protocol_source.find("data[\"external_player_id\"] = external_id") != -1)
	assert(protocol_source.find("data[\"dev_player_id\"] = external_id") != -1)
	assert(server_source.find("message.auth_provider") != -1)
	assert(server_source.find("message.external_id") != -1)
	assert(server_source.find("findByProviderExternal(provider, externalId)") != -1)
	print("Two client identity payload test passed.")
	quit()
