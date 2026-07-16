extends SceneTree

func _init() -> void:
	var profile_source := FileAccess.get_file_as_string("res://scripts/services/profile_service.gd")
	var home_source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var protocol_source := FileAccess.get_file_as_string("res://server/src/protocol.ts")
	assert(profile_source.contains("profile[\"mock_purchase_allowed\"] = bool(profile_snapshot.get(\"mock_purchase_allowed\", false))"))
	assert(home_source.contains("var allowed := bool(_player_profile.get(\"mock_purchase_allowed\", false))"))
	assert(home_source.contains("button.disabled = not allowed"))
	assert(home_source.contains("button.text = str(control.get(\"purchase_text\", \"\")) if allowed else _t(\"common.coming_soon\").to_upper()"))
	assert(home_source.contains("if not bool(_player_profile.get(\"mock_purchase_allowed\", false)):\n\t\treturn"))
	assert(protocol_source.contains("mock_purchase_allowed: boolean;"))
	quit()
