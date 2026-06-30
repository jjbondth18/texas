extends SceneTree

const LocalMockBackendScript := preload("res://scripts/services/local_mock_backend.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
const PublicTableRegistryScript := preload("res://scripts/services/public_table_registry.gd")

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	_require(source.contains("CREATE PRIVATE ROOM"), "Friends Room Create must open a Create Private Room setup")
	_require(source.contains("_show_private_room_setup"), "Create Private Room button must show setup first")
	_require(source.contains("_confirm_private_room_setup"), "Private setup must have a confirm action")
	_require(source.contains("STARTING STACK / BUY-IN"), "Private setup must include Starting Stack / Buy-in")
	_require(source.contains("Private casual room. Not listed in public tables."), "Private setup must clarify private casual")
	_require(source.contains("Gem private rooms are reserved for future private match support."), "Private Gem option must be visible as a future option")
	_require(source.contains("_private_room_setup_mode = \"gem\""), "Private Gem tab must not be blacked out")

	PublicTableRegistryScript.reset()
	var backend := LocalMockBackendScript.new()
	var context := backend.create_friends_room(PlayerProfileScript.default_profile(), {
		"buy_in": 50000,
		"small_blind": 100,
		"big_blind": 200,
		"max_hands": 999,
		"max_players": 6,
	})
	_require(["private_room", "private_casual"].has(String(context.get("table_type", ""))), "private room context must use private table type")
	_require(String(context.get("room_id", "")) != "", "private room creation must generate a room code")
	_require(PublicTableRegistryScript.list_public_tables().is_empty(), "private room must not enter public table list")
	var table_session := Dictionary(context.get("table_session", {}))
	_require(int(table_session.get("buy_in", 0)) == 50000, "private room must keep setup starting stack")
	_require(int(table_session.get("big_blind", 0)) == 200, "private room must keep setup blinds")
	PublicTableRegistryScript.reset()
	print("Private room create setup test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
