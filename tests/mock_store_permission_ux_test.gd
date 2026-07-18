extends SceneTree

func _init() -> void:
	var home_source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(home_source.contains("var allowed: bool = bool(_profile_server_connected and _store_commerce_available and _steam_commerce_service != null"))
	assert(home_source.contains("button.disabled = not allowed"))
	assert(not home_source.contains("func _show_mock_purchase_confirm"))
	assert(not home_source.contains("StoreMockServiceScript"))
	assert(home_source.contains("BUY WITH STEAM"))
	quit()
