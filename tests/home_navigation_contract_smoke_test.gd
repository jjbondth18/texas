extends SceneTree

const AppRoutes := preload("res://scripts/app/app_routes.gd")
const MockDataProvider := preload("res://scripts/demo/mock_data_provider.gd")
const StoreViewModel := preload("res://scripts/app/store_view_model.gd")
const ProfileViewModel := preload("res://scripts/app/profile_view_model.gd")
const SettingsViewModel := preload("res://scripts/app/settings_view_model.gd")

func _init() -> void:
	_assert(AppRoutes.is_known_route("home"), "home route missing")
	_assert(AppRoutes.is_known_route("play"), "play route missing")
	_assert(AppRoutes.is_known_route("replay"), "replay route missing")
	_assert(AppRoutes.is_known_route("store"), "store route missing")
	_assert(AppRoutes.is_known_route("profile"), "profile route missing")
	_assert(AppRoutes.is_known_route("settings"), "settings route missing")

	var lobby := MockDataProvider.get_lobby_view_model()
	_assert(Array(lobby.get("main_nav", [])).size() == 6, "main nav must have 6 items")
	_assert(Array(lobby.get("modes", [])).size() == 5, "play modes must have 5 cards")

	var expected_mode_ids := ["quick_play", "room_browser", "private_table", "training", "events"]
	var actual_mode_ids: Array[String] = []
	for mode in Array(lobby["modes"]):
		actual_mode_ids.append(String(Dictionary(mode).get("id", "")))
		_assert(Dictionary(mode).has("route"), "mode missing route")
	_assert(actual_mode_ids == expected_mode_ids, "play mode ids changed")

	_assert(StoreViewModel.new().to_dict().has("tabs"), "store skeleton missing")
	_assert(ProfileViewModel.new().to_dict().has("sections"), "profile skeleton missing")
	_assert(SettingsViewModel.new().to_dict().has("sections"), "settings skeleton missing")

	print("Home navigation contract smoke test passed.")
	quit(0)

func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
