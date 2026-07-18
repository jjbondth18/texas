extends SceneTree

func _init() -> void:
	var service_source := FileAccess.get_file_as_string("res://scripts/services/steam_commerce_service.gd")
	var home_source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var ws_source := FileAccess.get_file_as_string("res://scripts/network/poker_ws_client.gd")
	assert(service_source.contains('const AUTHORIZATION_SIGNAL := "microtransaction_auth_response"'))
	assert(service_source.contains("_handled_callbacks.has(callback_key)"))
	assert(service_source.contains("_pending_order_ids.has(order_id_text)"))
	assert(home_source.contains("register_pending_order"))
	assert(home_source.contains("get_store_purchase_status"))
	assert(home_source.contains("PURCHASE COMPLETE"))
	assert(home_source.contains("VIEW WALLET"))
	assert(ws_source.contains("store_purchase_authorization"))
	assert(ws_source.contains("apply_server_profile" ) or ws_source.contains("_emit_profile_payload(message)"))
	quit()
