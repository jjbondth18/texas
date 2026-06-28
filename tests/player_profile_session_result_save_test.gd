extends SceneTree

const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
const ProfileServiceScript := preload("res://scripts/services/profile_service.gd")

func _init() -> void:
	ProfileServiceScript.reset_mock_profile()
	var service := ProfileServiceScript.new()
	var before := service.get_current_profile()
	var starting_chips: int = PlayerProfileScript.get_total_chips(before)

	var after := service.apply_session_result({
		"session_profit": 1500,
		"hands_played": 5,
		"hands_won": 2,
		"biggest_pot": 3200,
		"best_hand_desc": "Flush",
	})

	_require(PlayerProfileScript.get_total_chips(after) == starting_chips + 1500, "total_chips must increase by session profit")
	_require(int(after.get("total_sessions_played", 0)) == int(before.get("total_sessions_played", 0)) + 1, "sessions played must increment")
	_require(int(after.get("total_hands_played", 0)) == int(before.get("total_hands_played", 0)) + 5, "hands played must accumulate")
	_require(int(after.get("total_hands_won", 0)) == int(before.get("total_hands_won", 0)) + 2, "hands won must accumulate")
	_require(int(after.get("total_profit", 0)) == int(before.get("total_profit", 0)) + 1500, "total profit must accumulate")
	_require(int(after.get("biggest_pot", 0)) >= 3200, "biggest pot must update")
	_require(String(after.get("best_hand_desc", "")) == "Flush", "best hand must update")
	_require(int(after.get("best_session_profit", 0)) >= 1500, "best session profit must update")

	ProfileServiceScript.reset_mock_profile()
	print("Player profile session result save test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
