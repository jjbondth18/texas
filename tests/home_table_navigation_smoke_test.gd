extends SceneTree

const ScreenNavigator := preload("res://scripts/app/screen_navigator.gd")

func _init() -> void:
	_assert(ResourceLoader.exists(ScreenNavigator.HOME_SCENE), "home scene missing")
	_assert(ResourceLoader.exists(ScreenNavigator.POKER_TABLE_SCENE), "poker table scene missing")
	_assert(ScreenNavigator.scene_for_play_mode("quick_play") == ScreenNavigator.POKER_TABLE_SCENE, "quick_play must open table")
	_assert(ScreenNavigator.scene_for_play_mode("training") == ScreenNavigator.POKER_TABLE_SCENE, "training must open table")
	_assert(ScreenNavigator.scene_for_play_mode("room_browser") == "", "room_browser must not open table yet")
	_assert(ScreenNavigator.scene_for_play_mode("private_table") == "", "private_table must not open table yet")
	_assert(ScreenNavigator.scene_for_play_mode("events") == "", "events must not open table yet")
	_assert(ScreenNavigator.HOME_SCENE == "res://scenes/screens/home_lobby_screen.tscn", "return route must resolve to home")
	print("Home table navigation smoke test passed.")
	quit(0)

func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
