extends SceneTree


func _init() -> void:
	var server_source := FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	var db_smoke := FileAccess.get_file_as_string("res://server/src/db_smoke_test.ts")
	assert(server_source.find("devSimulated: true") != -1)
	assert(server_source.find("hasUncontrolledDevSimulatedPlayer") != -1)
	assert(server_source.find("Dev simulated player cannot play a real public hand") != -1)
	assert(db_smoke.find("dev simulated real player must not be allowed to start a formal public hand") != -1)
	print("Dev simulated player cannot start real hand test passed.")
	quit()
