extends SceneTree

const DealerLibraryScript := preload("res://scripts/data/dealer_library.gd")

func _init() -> void:
	var ids: Array = DealerLibraryScript.get_all_dealer_ids()
	_require(ids.size() >= 11, "dealer helper should expose processed dealer ids")
	_require(DealerLibraryScript.get_default_dealer_id() == "dealer_01_dog", "default dealer id should be stable")
	var random_id: String = DealerLibraryScript.get_random_dealer_id("stable-test-seed")
	_require(ids.has(random_id), "random dealer id should come from processed dealer list")
	var texture_path: String = DealerLibraryScript.get_dealer_texture_path(random_id)
	_require(texture_path.begins_with("res://assets/croupier/processed/"), "dealer texture path should use processed assets")
	_require(FileAccess.file_exists(texture_path), "dealer texture path should exist")
	print("Dealer helper assets test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
