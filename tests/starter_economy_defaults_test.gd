extends SceneTree

const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")

func _init() -> void:
	var profile: Dictionary = PlayerProfileScript.default_profile()
	_require(PlayerProfileScript.get_total_chips(profile) == 30000, "new local profile should start with 30,000 chips.")
	_require(PlayerProfileScript.get_total_gems(profile) == 500, "new local profile should start with 500 gems.")
	_require(PlayerProfileScript.table_buy_in(profile) == 2000, "default table buy-in should be 2,000.")

	var old_profile := {
		"player_id": "old_profile",
		"name": "Old Profile",
		"total_chips": 1234,
		"chips": 1234,
		"gems": 7,
	}
	var normalized: Dictionary = PlayerProfileScript.normalized_dict(old_profile)
	_require(PlayerProfileScript.get_total_chips(normalized) == 1234, "old profile chips must not be overwritten.")
	_require(PlayerProfileScript.get_total_gems(normalized) == 7, "old profile gems must not be overwritten.")

	var home_source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	_require(home_source.find("CHIP_BUY_IN_OPTIONS := [1000, 2000, 5000, 10000, 20000, 50000]") != -1, "Quick/Browser/Friends chip buy-ins should include beginner stakes.")
	_require(home_source.find("_selected_quick_buy_in := 2000") != -1, "Quick default buy-in should be 2,000.")
	_require(home_source.find("1000 if total_chips < 5000 else 2000") != -1, "Quick should recommend 1,000 buy-in below 5,000 wallet chips.")
	print("Starter economy defaults test passed.")
	quit()

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
