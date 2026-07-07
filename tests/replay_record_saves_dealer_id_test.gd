extends SceneTree

const HandReplayRecordScript := preload("res://scripts/replay/hand_replay_record.gd")

func _init() -> void:
	_test_local_record_includes_dealer_id()
	var source: String = FileAccess.get_file_as_string("res://server/src/replay.ts")
	_require(source.find("dealer_id: meta.dealerId") != -1, "server replay record should include dealer_id")
	print("Replay record dealer id test passed.")
	quit(0)


func _test_local_record_includes_dealer_id() -> void:
	var record: Dictionary = HandReplayRecordScript.from_local_flow(
		{"hand_data": {"hand_id": "hand_test"}, "seats": [], "table_log": []},
		{"table_id": "local_table"},
		{"mode": "training", "selected_dealer_id": "dealer_07_statue"}
	)
	_require(str(record.get("dealer_id", "")) == "dealer_07_statue", "local replay record should copy selected dealer id")


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
