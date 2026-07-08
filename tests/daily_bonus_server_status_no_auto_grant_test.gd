extends SceneTree

func _init() -> void:
	var room_manager_source := FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	var db_smoke_source := FileAccess.get_file_as_string("res://server/src/db_smoke_test.ts")
	_require(room_manager_source.find("this.loginBonus.status(client.id)") != -1, "hello/profile should read daily bonus status.")
	_require(room_manager_source.find("this.loginBonus.claimTodayIfNeeded(client.id)") == -1, "hello must not auto-claim daily bonus.")
	_require(db_smoke_source.find("hello should not auto-grant daily bonus chips") != -1, "db smoke should assert no login auto-grant.")
	print("Daily bonus server status no auto grant test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
