extends SceneTree

func _init() -> void:
	var lobby_source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	_require(lobby_source.find("LEGACY UNLOCKED") != -1, "legacy unlocked replay state should be visible")
	_require(lobby_source.find("CORRUPTED / COLLISION") != -1, "corrupted/collision replay state should be visible")
	_require(lobby_source.find("import_legacy_replay_entitlement") != -1, "client should support internal legacy replay entitlement import")
	_require(lobby_source.find("REPLAY AVAILABLE TO HAND PARTICIPANTS ONLY") != -1, "non-participants should see an access explanation instead of a purchase button")
	_require(lobby_source.find("CHECKING ACCESS...") != -1, "official replay actions should wait for server access")
	_require(lobby_source.find("not bool(access.get(\"participant\", false))") != -1, "non-participants must not send unlock requests")
	var repo_source := FileAccess.get_file_as_string("res://scripts/replay/replay_repository.gd")
	_require(repo_source.find("\"checksum\"") != -1 and repo_source.find("\"key_version\"") != -1 and repo_source.find("\"algorithm\"") != -1, "unlock cache should validate checksum/key_version/algorithm")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
