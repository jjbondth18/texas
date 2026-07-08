extends SceneTree

const LocalMockBackendScript := preload("res://scripts/services/local_mock_backend.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
const PublicTableRegistryScript := preload("res://scripts/services/public_table_registry.gd")


func _init() -> void:
	PublicTableRegistryScript.reset()
	var backend := LocalMockBackendScript.new()
	var context: Dictionary = backend.quick_join_public_table(PlayerProfileScript.default_profile(), {
		"table_type": "public_gem",
		"currency": "gems",
		"buy_in": 50,
		"small_blind": 2,
		"big_blind": 5,
		"hand_count": 10,
	})
	_require(str(context.get("table_type", "")) == "public_gem", "Quick Gem must create a public_gem table when no match exists.")
	_require(str(context.get("currency", "")) == "gems", "Quick Gem created table must use gems currency.")
	_require(int(context.get("buy_in", 0)) == 50, "Quick Gem created table must preserve selected gem buy-in.")
	PublicTableRegistryScript.reset()
	print("Quick Gem create table test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
