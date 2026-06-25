extends SceneTree

const MockDataProviderScript := preload("res://scripts/demo/mock_data_provider.gd")
const AppRoutesScript := preload("res://scripts/app/app_routes.gd")

var _failures: Array[String] = []

func _initialize() -> void:
	_check_lobby_view_model()
	_check_room_browser_view_model()
	_check_table_view_model()
	_check_routes()
	if _failures.is_empty():
		print("ViewModel contract smoke test passed.")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)

func _check_lobby_view_model() -> void:
	var vm: Dictionary = MockDataProviderScript.get_lobby_view_model()
	_require(vm.has("player"), "LobbyViewModel must include player.")
	var player: Dictionary = vm.get("player", {})
	for field in ["name", "chips", "gems"]:
		_require(player.has(field), "LobbyViewModel player must include %s." % field)
	var modes: Array = vm.get("modes", [])
	_require(modes.size() == 5, "LobbyViewModel modes count must be 5.")
	for mode in modes:
		for field in ["id", "title", "subtitle", "image", "enabled"]:
			_require(Dictionary(mode).has(field), "Each lobby mode must include %s." % field)
	var daily_bonus: Dictionary = vm.get("daily_bonus", {})
	_require(Array(daily_bonus.get("days", [])).size() == 7, "Daily bonus must include 7 days.")

func _check_room_browser_view_model() -> void:
	var vm: Dictionary = MockDataProviderScript.get_room_browser_view_model()
	_require(vm.has("rooms"), "RoomBrowserViewModel must include rooms.")
	_require(Array(vm.get("rooms", [])).size() >= 1, "RoomBrowserViewModel rooms must not be empty.")

func _check_table_view_model() -> void:
	var vm: Dictionary = MockDataProviderScript.get_table_view_model()
	for field in ["table_id", "pot", "phase", "available_actions"]:
		_require(vm.has(field), "TableViewModel must include %s." % field)

func _check_routes() -> void:
	for route_id in [AppRoutesScript.HOME, AppRoutesScript.PLAY, AppRoutesScript.QUICK_PLAY, AppRoutesScript.CASH_TABLES, AppRoutesScript.TABLE, AppRoutesScript.EXIT]:
		_require(AppRoutesScript.is_known_route(route_id), "AppRoutes must recognize %s." % route_id)

func _require(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
