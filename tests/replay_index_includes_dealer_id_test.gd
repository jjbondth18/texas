extends SceneTree

func _init() -> void:
	var repository_source: String = FileAccess.get_file_as_string("res://scripts/replay/replay_repository.gd")
	var service_source: String = FileAccess.get_file_as_string("res://scripts/services/replay_service.gd")
	var data_source: String = FileAccess.get_file_as_string("res://scripts/data/replay_record.gd")
	_require(repository_source.find("\"dealer_id\": str(record.get(\"dealer_id\", \"\"))") != -1, "replay index should persist dealer_id")
	_require(service_source.find("\"dealer_id\": str(entry.get(\"dealer_id\", \"\"))") != -1, "replay service should expose dealer_id")
	_require(data_source.find("var dealer_id") != -1, "ReplayRecord should carry dealer_id")
	print("Replay index dealer id test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
