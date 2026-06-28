extends SceneTree

const HomeScene := preload("res://scenes/screens/home_lobby_screen.tscn")
const ProfileServiceScript := preload("res://scripts/services/profile_service.gd")

func _initialize() -> void:
	ProfileServiceScript.reset_mock_profile()
	var service := ProfileServiceScript.new()
	service.apply_session_result({
		"session_profit": 1500,
		"hands_played": 5,
		"hands_won": 2,
		"biggest_pot": 3200,
		"best_hand_desc": "Flush",
	})

	var home := HomeScene.instantiate()
	root.add_child(home)
	await process_frame
	await process_frame
	home.call("_reload_player_profile")
	await process_frame

	var labels: Dictionary = Dictionary(home.get("_profile_stats_labels"))
	_require((labels.get("total_chips") as Label).text.find("26,000") != -1, "profile panel must show updated chips")
	_require((labels.get("total_sessions_played") as Label).text == "1", "profile panel must show sessions")
	_require((labels.get("total_hands_played") as Label).text == "5", "profile panel must show total hands")
	_require((labels.get("total_hands_won") as Label).text == "2", "profile panel must show hands won")
	_require((labels.get("win_rate") as Label).text == "40.0%", "profile panel must show win rate")
	_require((labels.get("total_profit") as Label).text == "+1,500", "profile panel must show total profit")
	_require((labels.get("biggest_pot") as Label).text == "3,200", "profile panel must show biggest pot")
	_require((labels.get("best_hand_desc") as Label).text == "Flush", "profile panel must show best hand")

	ProfileServiceScript.reset_mock_profile()
	print("Home profile panel data binding test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
