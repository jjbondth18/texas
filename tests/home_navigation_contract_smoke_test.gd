extends SceneTree

const AppRoutes := preload("res://scripts/app/app_routes.gd")
const MockDataProvider := preload("res://scripts/demo/mock_data_provider.gd")

func _init() -> void:
	for route_id in ["home", "play", "replay", "store", "profile", "settings"]:
		_assert(AppRoutes.is_known_route(route_id), "missing main route: %s" % route_id)

	var lobby := MockDataProvider.get_lobby_view_model()
	_assert(Array(lobby.get("main_nav", [])).size() == 6, "main_nav must have 6 items")
	_assert(Array(lobby.get("modes", [])).size() == 5, "modes must have 5 items")

	var expected_ids := ["quick_play", "room_browser", "private_table", "training", "events"]
	var actual_ids: Array[String] = []
	for mode in Array(lobby.get("modes", [])):
		actual_ids.append(String(Dictionary(mode).get("id", "")))
	_assert(actual_ids == expected_ids, "PLAY mode ids do not match contract")

	print("Home navigation contract smoke test passed.")
	quit(0)

func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
