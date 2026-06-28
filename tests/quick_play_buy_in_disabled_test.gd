extends SceneTree

const HomeScene := preload("res://scenes/screens/home_lobby_screen.tscn")
const ProfileServiceScript := preload("res://scripts/services/profile_service.gd")

func _initialize() -> void:
	ProfileServiceScript.reset_mock_profile()
	var service := ProfileServiceScript.new()
	var profile: Dictionary = service.get_current_profile()
	profile["total_chips"] = 9000
	profile["chips"] = 9000
	profile["last_daily_reward_date"] = "2026-06-28"
	profile["daily_reward_claimed_today"] = true
	service.save_current_profile(profile)

	var home := HomeScene.instantiate()
	root.add_child(home)
	await process_frame
	await process_frame
	home.call("_show_quick_play_setup")
	await process_frame

	var buy_in_buttons: Dictionary = Dictionary(home.get("_quick_buy_in_buttons"))
	var high_buy_in_button: Button = buy_in_buttons.get(10000) as Button
	_require(high_buy_in_button != null and high_buy_in_button.disabled, "buy-in above wallet chips must be disabled")

	ProfileServiceScript.reset_mock_profile()
	print("Quick play buy-in disabled test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
