extends SceneTree

const LocalMockBackendScript := preload("res://scripts/services/local_mock_backend.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")


func _init() -> void:
	var context: Dictionary = LocalMockBackendScript.new().create_friends_room(PlayerProfileScript.default_profile(), {
		"table_type": "private_gem",
		"currency": "gems",
		"buy_in": 50,
		"small_blind": 2,
		"big_blind": 5,
	})
	_require(str(context.get("table_type", "")) == "private_gem", "Private Gem room context must use private_gem.")
	_require(str(context.get("currency", "")) == "gems", "Private Gem room context must use gems.")
	_require(str(context.get("room_code", "")) != "", "Private Gem room must still generate a room code.")
	print("Private Gem room create code test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
