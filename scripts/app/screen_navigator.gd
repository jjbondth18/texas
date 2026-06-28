extends RefCounted
class_name ScreenNavigator

const HOME_SCENE := "res://scenes/screens/home_lobby_screen.tscn"
const POKER_TABLE_SCENE := "res://scenes/screens/poker_table_screen.tscn"

const TableLaunchContextScript := preload("res://scripts/app/table_launch_context.gd")

static func open_poker_table(tree: SceneTree, launch_mode: String = "quick_play", table_id: String = "mock_table_001", player_profile: Dictionary = {}) -> void:
	TableLaunchContextScript.configure(launch_mode, table_id, player_profile)
	tree.change_scene_to_file(POKER_TABLE_SCENE)

static func open_poker_table_with_context(tree: SceneTree, table_context: Dictionary) -> void:
	TableLaunchContextScript.configure_from_context(table_context)
	tree.change_scene_to_file(POKER_TABLE_SCENE)

static func return_home(tree: SceneTree) -> void:
	tree.change_scene_to_file(HOME_SCENE)

static func should_open_table_for_play_mode(mode_id: String) -> bool:
	return mode_id in ["quick_play", "training"]

static func should_open_local_room_for_play_mode(mode_id: String) -> bool:
	return mode_id in ["private_table", "friends_room"]

static func scene_for_play_mode(mode_id: String) -> String:
	if should_open_table_for_play_mode(mode_id):
		return POKER_TABLE_SCENE
	return ""
