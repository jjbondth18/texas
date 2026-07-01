extends SceneTree

const LocalMockBackendScript := preload("res://scripts/services/local_mock_backend.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
const PublicTableRegistryScript := preload("res://scripts/services/public_table_registry.gd")


func _init() -> void:
	var backend := LocalMockBackendScript.new()
	PublicTableRegistryScript.reset()
	var joined: Dictionary = backend.quick_join_public_table(PlayerProfileScript.default_profile(), {"buy_in": 10000, "small_blind": 50, "big_blind": 100, "hand_count": 10})
	var listed: Array = PublicTableRegistryScript.list_public_tables()
	_require(not joined.is_empty(), "Quick must create a table when the browser is empty.")
	_require(listed.size() == 1, "Quick-created table must appear in Browser list.")
	_require(str(Dictionary(listed[0]).get("table_id", "")) == str(joined.get("table_id", "")), "Browser list must include the same Quick-created table.")
	PublicTableRegistryScript.reset()
	print("Quick-created table appears in browser test passed.")
	quit()


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
