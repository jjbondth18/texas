extends RefCounted
class_name PokerProtocol

const HELLO := "hello"
const CREATE_ROOM := "create_room"
const JOIN_ROOM := "join_room"
const SIT_DOWN := "sit_down"
const LEAVE_SEAT := "leave_seat"
const CASH_OUT := "cash_out"
const READY := "ready"
const START_HAND := "start_hand"
const PLAYER_ACTION := "player_action"
const ADD_TABLE_CHIPS := "add_table_chips"
const GET_PROFILE := "get_profile"
const TABLE_SNAPSHOT := "table_snapshot"
const PRIVATE_SNAPSHOT := "private_snapshot"
const PROFILE_SNAPSHOT := "profile_snapshot"
const WALLET_SNAPSHOT := "wallet_snapshot"
const ERROR := "error"

const ACTION_FOLD := "fold"
const ACTION_CHECK := "check"
const ACTION_CALL := "call"
const ACTION_BET := "bet"
const ACTION_RAISE := "raise"
const ACTION_ALL_IN := "all_in"

static func encode(message: Dictionary) -> String:
	return JSON.stringify(message)

static func decode(payload: String) -> Dictionary:
	var parsed = JSON.parse_string(payload)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"type": ERROR, "error": "Invalid JSON message"}
	return parsed

static func hello(player_name: String = "", player_id: String = "", avatar_id: String = "") -> Dictionary:
	var data := {"name": player_name, "player_name": player_name}
	if player_id != "":
		data["player_id"] = player_id
	if avatar_id != "":
		data["avatar_id"] = avatar_id
	return _message(HELLO, data)

static func create_room() -> Dictionary:
	return _message(CREATE_ROOM)

static func join_room(room_id: String) -> Dictionary:
	return _message(JOIN_ROOM, {"room_id": room_id})

static func sit_down(seat_index: int, buy_in: int = 5000) -> Dictionary:
	return _message(SIT_DOWN, {"seat_index": seat_index, "buy_in": buy_in})

static func leave_seat() -> Dictionary:
	return _message(LEAVE_SEAT)

static func cash_out() -> Dictionary:
	return _message(CASH_OUT)

static func ready(is_ready: bool = true) -> Dictionary:
	return _message(READY, {"ready": is_ready})

static func start_hand() -> Dictionary:
	return _message(START_HAND)

static func player_action(action: String, amount: int = 0) -> Dictionary:
	var data := {"action": action}
	if amount > 0:
		data["amount"] = amount
	return _message(PLAYER_ACTION, data)

static func add_table_chips(amount: int) -> Dictionary:
	return _message(ADD_TABLE_CHIPS, {"amount": amount})

static func get_profile() -> Dictionary:
	return _message(GET_PROFILE)

static func _message(type_value: String, extra: Dictionary = {}) -> Dictionary:
	var result := {"type": type_value}
	for key in extra.keys():
		result[key] = extra[key]
	return result
