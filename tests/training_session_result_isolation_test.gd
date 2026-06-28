extends SceneTree

const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
const ProfileServiceScript := preload("res://scripts/services/profile_service.gd")

func _init() -> void:
	ProfileServiceScript.reset_mock_profile()
	var service := ProfileServiceScript.new()
	var before := service.get_current_profile()
	var before_unlocked: Array = Array(before.get("unlocked_avatar_ids", []))

	var after := service.apply_session_result({
		"mode": "training",
		"table_type": "training_ai",
		"uses_practice_chips": true,
		"affects_account_balance": false,
		"session_profit": 5000,
		"hands_played": 8,
		"hands_won": 4,
		"biggest_pot": 9000,
		"best_hand_desc": "Straight Flush",
	})

	_require(PlayerProfileScript.get_total_chips(after) == PlayerProfileScript.get_total_chips(before), "training must not change chip balance")
	_require(int(after.get("gems", 0)) == int(before.get("gems", 0)), "training must not change gem balance")
	_require(int(after.get("total_sessions_played", 0)) == int(before.get("total_sessions_played", 0)), "training must not increment sessions")
	_require(int(after.get("total_hands_played", 0)) == int(before.get("total_hands_played", 0)), "training must not increment hands played")
	_require(int(after.get("total_hands_won", 0)) == int(before.get("total_hands_won", 0)), "training must not increment hands won")
	_require(int(after.get("total_profit", 0)) == int(before.get("total_profit", 0)), "training must not change total profit")
	_require(int(after.get("biggest_pot", 0)) == int(before.get("biggest_pot", 0)), "training must not update biggest pot")
	_require(int(after.get("best_session_profit", 0)) == int(before.get("best_session_profit", 0)), "training must not update best session profit")
	_require(Array(after.get("unlocked_avatar_ids", [])) == before_unlocked, "training must not unlock ranked rewards")
	_require(service.get_last_unlocked_avatar_ids().is_empty(), "training must not report new unlocks")

	ProfileServiceScript.reset_mock_profile()
	print("Training session result isolation test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
