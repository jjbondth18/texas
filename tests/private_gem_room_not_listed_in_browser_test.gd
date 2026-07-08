extends SceneTree

const PublicTableRegistryScript := preload("res://scripts/services/public_table_registry.gd")


func _init() -> void:
	PublicTableRegistryScript.reset()
	PublicTableRegistryScript.add_mock_table({
		"table_id": "private_gem_mock",
		"table_type": "private_gem",
		"currency": "gems",
		"status": "waiting",
		"current_players": 2,
	})
	_require(PublicTableRegistryScript.list_public_tables().is_empty(), "Private Gem rooms must not appear in Browser public table list.")
	PublicTableRegistryScript.reset()
	print("Private Gem room not listed in Browser test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
