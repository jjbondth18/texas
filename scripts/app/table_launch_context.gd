extends RefCounted
class_name TableLaunchContext

const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")

static var launch_mode := "quick_play"
static var mode := "quick_play"
static var backend_type := "local_mock"
static var table_id := "mock_table_001"
static var room_id := ""
static var is_training := false
static var allow_debug_tools := false
static var ai_player_count := 0
static var buy_in := PlayerProfileScript.DEFAULT_TABLE_BUY_IN
static var small_blind := 25
static var big_blind := 50
static var seats: Array[Dictionary] = []
static var player_profile: Dictionary = PlayerProfileScript.default_profile()

static func configure(mode: String = "quick_play", id: String = "mock_table_001", profile: Dictionary = {}) -> void:
	launch_mode = mode
	TableLaunchContext.mode = mode
	table_id = id
	is_training = mode == "training"
	if not profile.is_empty():
		set_player_profile(profile)
	buy_in = PlayerProfileScript.table_buy_in(player_profile)
	backend_type = "local_mock"
	room_id = ""
	allow_debug_tools = is_training
	ai_player_count = 7 if mode in ["quick_play", "training"] else 0
	small_blind = 25
	big_blind = 50
	seats.clear()

static func reset() -> void:
	configure("quick_play", "mock_table_001", PlayerProfileScript.default_profile())

static func set_player_profile(profile: Dictionary) -> void:
	player_profile = PlayerProfileScript.normalized_dict(profile)

static func get_player_profile() -> Dictionary:
	if player_profile.is_empty():
		player_profile = PlayerProfileScript.default_profile()
	return player_profile.duplicate(true)

static func configure_from_context(context: Dictionary) -> void:
	if context.is_empty():
		configure()
		return
	mode = String(context.get("mode", "quick_play"))
	launch_mode = mode
	backend_type = String(context.get("backend_type", "local_mock"))
	table_id = String(context.get("table_id", "mock_table_001"))
	room_id = String(context.get("room_id", ""))
	is_training = bool(context.get("is_training", mode == "training"))
	allow_debug_tools = bool(context.get("allow_debug_tools", is_training))
	ai_player_count = int(context.get("ai_player_count", 0))
	buy_in = int(context.get("buy_in", PlayerProfileScript.DEFAULT_TABLE_BUY_IN))
	small_blind = int(context.get("small_blind", 25))
	big_blind = int(context.get("big_blind", 50))
	seats = []
	for seat in Array(context.get("seats", [])):
		seats.append(Dictionary(seat).duplicate(true))
	set_player_profile(Dictionary(context.get("local_player_profile", PlayerProfileScript.default_profile())))

static func get_current_table_context() -> Dictionary:
	return {
		"mode": mode,
		"backend_type": backend_type,
		"local_player_profile": get_player_profile(),
		"table_id": table_id,
		"room_id": room_id,
		"seats": seats.duplicate(true),
		"buy_in": buy_in,
		"small_blind": small_blind,
		"big_blind": big_blind,
		"is_training": is_training,
		"allow_debug_tools": allow_debug_tools,
		"ai_player_count": ai_player_count,
	}

static func has_seat_context() -> bool:
	return not seats.is_empty()
