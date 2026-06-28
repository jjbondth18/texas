extends SceneTree

const HomeScene := preload("res://scenes/screens/home_lobby_screen.tscn")
const ProfileServiceScript := preload("res://scripts/services/profile_service.gd")

func _initialize() -> void:
	ProfileServiceScript.reset_mock_profile()
	var service := ProfileServiceScript.new()
	var profile := service.apply_session_profit(3450)
	var expected_chips: int = int(profile.get("total_chips", profile.get("chips", 0)))

	var home := HomeScene.instantiate()
	root.add_child(home)
	await process_frame
	await process_frame

	home.call("_show_quick_play_setup")
	await process_frame

	var label: Label = home.get("_quick_play_setup_chips_label") as Label
	_require(label != null, "quick play setup chips label must exist")
	_require(label.text.find(_format_number(expected_chips)) != -1, "quick play setup must read updated profile chips")

	ProfileServiceScript.reset_mock_profile()
	print("Home setup reads updated profile chips test passed.")
	quit(0)

func _format_number(value: int) -> String:
	var text := str(value)
	var output := ""
	while text.length() > 3:
		output = "," + text.substr(text.length() - 3, 3) + output
		text = text.substr(0, text.length() - 3)
	return text + output

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
