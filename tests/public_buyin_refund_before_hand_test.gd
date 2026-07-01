extends SceneTree


func _init() -> void:
	var server_source := FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	var db_smoke := FileAccess.get_file_as_string("res://server/src/db_smoke_test.ts")
	assert(server_source.find("officialHandStarted") != -1)
	assert(server_source.find("left_before_official_hand") != -1)
	assert(db_smoke.find("pre-hand cash out should write left_before_official_hand wallet transaction") != -1)
	print("Public buy-in refund before hand test passed.")
	quit()
