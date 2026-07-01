extends SceneTree

func _init() -> void:
	var server_source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	var smoke_source: String = FileAccess.get_file_as_string("res://server/src/db_smoke_test.ts")

	_require(server_source.find("TABLE_SEAT_JOIN_ORDER_9P = [5, 8, 2, 6, 4, 9, 1, 7, 3]") != -1, "Server must keep objective 9-player seat order.")
	_require(server_source.find("firstAvailablePublicSeat") != -1 and server_source.find("isManagedChipRoom(room)") != -1, "Private rooms must use the managed chip-room auto-seat path.")
	_require(smoke_source.find("private creator should sit at objective seat 5") != -1, "DB smoke must verify private creator seat 5.")
	_require(smoke_source.find("private second player should sit at objective seat 8") != -1, "DB smoke must verify private second player seat 8.")
	print("Private room seat order test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
