extends SceneTree

const LocalMockBackendScript := preload("res://scripts/services/local_mock_backend.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
const PublicTableRegistryScript := preload("res://scripts/services/public_table_registry.gd")

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	_require(source.contains("CREATE PUBLIC TABLE"), "Table Browser Create must open a Create Public Table setup")
	_require(source.contains("_show_public_table_setup"), "Create Public Table button must show setup first")
	_require(source.contains("_confirm_public_table_setup"), "Public setup must have a confirm action")
	_require(source.contains("\"BUY-IN\" if public_table"), "Public setup must include Buy-in")
	_require(source.contains("BLINDS"), "Public setup must include Blinds")
	_require(source.contains("HAND COUNT"), "Public setup must include Hand Count")
	_require(source.contains("Gem public tables require secure server matchmaking."), "Public setup must show disabled Gem copy")
	_require(source.contains("var gem_disabled: bool = public_table"), "Public Gem tab must be disabled")
	_require(source.contains("_local_backend.create_public_table(_public_table_config_from_values"), "Public confirm must create a public table from setup values")

	PublicTableRegistryScript.reset()
	var backend := LocalMockBackendScript.new()
	var table := backend.create_public_table({
		"buy_in": 10000,
		"small_blind": 50,
		"big_blind": 100,
		"hand_count": 20,
		"max_players": 6,
		"created_by": PlayerProfileScript.DEFAULT_PLAYER_ID,
	})
	_require(String(table.get("table_type", "")) == "public_chip", "created public table must be public_chip")
	_require(int(table.get("buy_in", 0)) == 10000, "created public table must keep setup buy-in")
	_require(int(table.get("hand_count", 0)) == 20, "created public table must keep setup hand count")
	PublicTableRegistryScript.reset()
	print("Public table create setup test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
