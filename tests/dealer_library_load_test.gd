extends SceneTree

const DealerLibraryScript := preload("res://scripts/data/dealer_library.gd")
const TableSessionScript := preload("res://scripts/data/table_session.gd")

func _init() -> void:
	_test_library_loads_processed_pngs()
	_test_each_dealer_has_required_fields()
	_test_selected_dealer_name_and_texture_stay_in_sync()
	_test_legacy_default_maps_to_real_resource()
	print("Dealer library load test passed.")
	quit(0)


func _test_library_loads_processed_pngs() -> void:
	var dealers := DealerLibraryScript.list_dealers()
	_require(dealers.size() >= 11, "dealer library must load processed dealer PNG resources")
	var ids := DealerLibraryScript.dealer_ids()
	for expected_id in [
		"dealer_01_dog",
		"dealer_02_bear",
		"dealer_03_cat",
		"dealer_04_red_panda",
		"dealer_05_armor",
		"dealer_06_sloth",
		"dealer_07_statue",
		"dealer_08_horse",
		"dealer_09_owl",
		"dealer_10_frog",
		"dealer_11_walrus",
	]:
		_require(ids.has(expected_id), "dealer library missing %s" % expected_id)


func _test_each_dealer_has_required_fields() -> void:
	for dealer_item in DealerLibraryScript.list_dealers():
		var dealer := Dictionary(dealer_item)
		_require(String(dealer.get("id", "")) != "", "dealer id is required")
		_require(String(dealer.get("display_name", "")) != "", "dealer display_name is required")
		var texture_path := String(dealer.get("texture_path", ""))
		_require(texture_path.begins_with("res://assets/croupier/processed/"), "dealer texture_path must use processed assets")
		_require(texture_path.ends_with(".png"), "dealer texture_path must point to PNG")
		_require(FileAccess.file_exists(texture_path), "dealer texture file must exist: %s" % texture_path)


func _test_selected_dealer_name_and_texture_stay_in_sync() -> void:
	var session := TableSessionScript.new()
	var seats := _solo_ai_seats()
	var changed := session.select_dealer_cosmetic("dealer_07_statue", seats)
	_require(changed, "solo AI table should change dealer")
	var dealer := DealerLibraryScript.get_dealer(session.selected_dealer_id)
	_require(String(dealer.get("display_name", "")) == "Statue", "selected dealer name must match selected id")
	_require(String(dealer.get("texture_path", "")).ends_with("dealer_07_statue.png"), "selected dealer texture must match selected id")


func _test_legacy_default_maps_to_real_resource() -> void:
	_require(DealerLibraryScript.normalize_dealer_id("default") == "dealer_01_dog", "legacy default must map to dog resource id")


func _solo_ai_seats() -> Array:
	return [
		{"occupied": true, "status": "sitting", "player_id": "local_player", "is_local": true, "is_ai": false, "chips": 10000},
		{"occupied": true, "status": "sitting", "player_id": "ai_player_001", "is_local": false, "is_ai": true, "chips": 10000},
	]


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
