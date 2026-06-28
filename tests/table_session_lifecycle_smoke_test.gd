extends SceneTree

const LocalMockBackendScript := preload("res://scripts/services/local_mock_backend.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
const TableLaunchContextScript := preload("res://scripts/app/table_launch_context.gd")
const TableSessionScript := preload("res://scripts/data/table_session.gd")

func _initialize() -> void:
	var profile := PlayerProfileScript.default_profile()
	var backend := LocalMockBackendScript.new()
	var context := backend.create_quick_play_table(profile)
	_require(int(context.get("buy_in", 0)) == 20000, "quick play buy-in must be 20000 for default profile")
	_require(int(context.get("small_blind", 0)) == 25, "quick play small blind must be 25")
	_require(int(context.get("big_blind", 0)) == 50, "quick play big blind must be 50")
	_require(int(context.get("max_hands", 0)) == 10, "quick play max_hands must be 10")

	TableLaunchContextScript.configure_from_context(context)
	var launch_context := TableLaunchContextScript.get_current_table_context()
	_require(int(launch_context.get("max_hands", 0)) == 10, "launch context must preserve max_hands")
	_require(Dictionary(launch_context.get("table_session", {})).has("session_start_chips"), "launch context must expose table_session")

	var session := TableSessionScript.from_context(launch_context)
	_require(session.can_start_next_hand(), "new session must be able to start")
	_require(session.begin_next_hand() == 1, "first session hand index must be 1")
	session.record_hand_result({
		"winner_seats": [5],
		"winner_names": ["Luna0581"],
		"win_amount": 300,
		"hand_description": "One Pair",
		"pot_before_settlement": 300,
		"pot_after_settlement": 0,
	}, 5, 20300)
	_require(session.hands_played == 1, "session must count hands played")
	_require(session.hands_won == 1, "session must count local wins")
	_require(session.session_profit == 300, "session profit must follow current table chips")
	_require(session.biggest_pot == 300, "session must track biggest pot")

	print("Table session lifecycle smoke test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
