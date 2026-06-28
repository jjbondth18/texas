extends SceneTree

const HomeScene := preload("res://scenes/screens/home_lobby_screen.tscn")
const LocalMockBackendScript := preload("res://scripts/services/local_mock_backend.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
const ProfileServiceScript := preload("res://scripts/services/profile_service.gd")

func _initialize() -> void:
	ProfileServiceScript.reset_mock_profile()
	var home := HomeScene.instantiate()
	root.add_child(home)
	await process_frame
	await process_frame

	home.call("_on_avatar_selected", "1_01")
	await process_frame
	var profile: Dictionary = Dictionary(home.get("_player_profile"))
	_require(PlayerProfileScript.get_avatar_id(profile) == "1_01", "home profile must update selected avatar")

	var top_bar: TopBar = home.get("_top_bar") as TopBar
	var top_avatar: TextureRect = top_bar.get("_avatar_rect") as TextureRect
	_require(top_avatar != null and top_avatar.visible and top_avatar.texture != null, "top bar avatar must refresh after selection")

	var context: Dictionary = LocalMockBackendScript.new().create_quick_play_table(profile, {"buy_in": 5000})
	var local_seat: Dictionary = {}
	for seat_item in Array(context.get("seats", [])):
		var seat: Dictionary = Dictionary(seat_item)
		if bool(seat.get("is_local", false)):
			local_seat = seat
			break
	_require(String(local_seat.get("avatar_id", "")) == "1_01", "table launch local player must use selected avatar")

	ProfileServiceScript.reset_mock_profile()
	print("Home avatar sync test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
