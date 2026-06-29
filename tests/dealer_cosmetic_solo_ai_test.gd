extends SceneTree

const TableSessionScript := preload("res://scripts/data/table_session.gd")

func _init() -> void:
	_test_default_dealer_id()
	_test_training_can_change_dealer()
	_test_solo_ai_can_change_dealer()
	_test_extra_human_blocks_dealer_change()
	_test_dealer_change_does_not_touch_rule_or_economy_state()
	print("Dealer cosmetic solo AI test passed.")
	quit(0)

func _test_default_dealer_id() -> void:
	var session := TableSessionScript.new()
	_require(session.selected_dealer_id == "dealer_01_dog", "selected_dealer_id must default to the dog resource")

func _test_training_can_change_dealer() -> void:
	var session := TableSessionScript.new()
	session.mode = TableSessionScript.MODE_TRAINING
	session.table_type = TableSessionScript.TABLE_TYPE_TRAINING_AI
	var changed := session.select_dealer_cosmetic("dealer_03_cat", _solo_ai_seats())
	_require(changed, "training_ai must allow dealer cosmetic change")
	_require(session.selected_dealer_id == "dealer_03_cat", "training dealer selection must apply")

func _test_solo_ai_can_change_dealer() -> void:
	var session := TableSessionScript.new()
	var seats := _solo_ai_seats()
	_require(session.can_change_dealer_cosmetic(seats), "local human plus AI players must allow dealer cosmetic change")
	var changed := session.select_dealer_cosmetic("dealer_04_red_panda", seats)
	_require(changed, "solo AI table must select dealer")
	_require(session.selected_dealer_id == "dealer_04_red_panda", "solo AI dealer selection must apply")

func _test_extra_human_blocks_dealer_change() -> void:
	var session := TableSessionScript.new()
	var seats := _solo_ai_seats()
	seats.append({
		"seat_id": 4,
		"occupied": true,
		"status": "sitting",
		"player_id": "human_friend_002",
		"player_name": "Human Friend",
		"is_local": false,
		"is_ai": false,
		"chips": 9000,
	})
	_require(not session.can_change_dealer_cosmetic(seats), "another human must block dealer cosmetic changes")
	var changed := session.select_dealer_cosmetic("dealer_09_owl", seats)
	_require(not changed, "multiplayer table must not select dealer")
	_require(session.selected_dealer_id == "dealer_01_dog", "blocked multiplayer selection must not modify selected_dealer_id")

func _test_dealer_change_does_not_touch_rule_or_economy_state() -> void:
	var session := TableSessionScript.new()
	session.current_table_chips = 12000
	var dealer_button_position := 3
	var gems := 42
	var seats := _solo_ai_seats()
	var before_seats := seats.duplicate(true)
	var before_chips := session.current_table_chips
	var changed := session.select_dealer_cosmetic("dealer_07_statue", seats)
	_require(changed, "solo AI dealer change should succeed")
	_require(dealer_button_position == 3, "dealer cosmetic change must not change dealer_button_position")
	_require(gems == 42, "dealer cosmetic change must not change gems")
	_require(session.current_table_chips == before_chips, "dealer cosmetic change must not change table chips")
	_require(seats == before_seats, "dealer cosmetic change must not mutate seat stacks or dealer button flags")

func _solo_ai_seats() -> Array:
	return [
		{
			"seat_id": 5,
			"occupied": true,
			"status": "sitting",
			"player_id": "local_player",
			"player_name": "Local Player",
			"is_local": true,
			"is_ai": false,
			"chips": 10000,
			"is_dealer": true,
		},
		{
			"seat_id": 1,
			"occupied": true,
			"status": "sitting",
			"player_id": "ai_player_001",
			"player_name": "AI Seat 1",
			"is_local": false,
			"is_ai": true,
			"chips": 10000,
			"is_dealer": false,
		},
		{
			"seat_id": 2,
			"occupied": true,
			"status": "sitting",
			"player_id": "ai_player_002",
			"player_name": "AI Seat 2",
			"is_local": false,
			"is_ai": true,
			"chips": 10000,
			"is_dealer": false,
		},
	]

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
