extends SceneTree

const ProfileServiceScript := preload("res://scripts/services/profile_service.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")

func _init() -> void:
	ProfileServiceScript.reset_mock_profile()
	var service := ProfileServiceScript.new()
	var profile: Dictionary = service.get_current_profile()
	profile["total_chips"] = 24500
	profile["chips"] = 24500
	service.save_current_profile(profile)

	var after_buy_in: Dictionary = service.deduct_table_buy_in(20000)
	_require(PlayerProfileScript.get_total_chips(after_buy_in) == 4500, "buy-in must be deducted from wallet")

	var after_session: Dictionary = service.apply_session_result({
		"mode": "quick_play",
		"affects_account_balance": true,
		"buy_in_deducted_from_wallet": true,
		"buy_in": 20000,
		"session_end_chips": 18850,
		"session_profit": -1150,
		"hands_played": 10,
		"hands_won": 2,
	})
	_require(PlayerProfileScript.get_total_chips(after_session) == 23350, "final table chips must be refunded to wallet")
	_require(int(after_session.get("total_profit", 0)) == -1150, "profile profit stats must track session profit")

	ProfileServiceScript.reset_mock_profile()
	print("Wallet buy-in deduct and refund test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
