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
const GET_AVATAR_CATALOG := "get_avatar_catalog"
const BUY_AVATAR := "buy_avatar"
const SELECT_AVATAR := "select_avatar"
const MOCK_PURCHASE := "mock_purchase"
const LIST_TABLES := "list_tables"
const CREATE_TABLE := "create_table"
const JOIN_TABLE := "join_table"
const TABLE_SNAPSHOT := "table_snapshot"
const PRIVATE_SNAPSHOT := "private_snapshot"
const SIT_DOWN_RESULT := "sit_down_result"
const PROFILE_SNAPSHOT := "profile_snapshot"
const WALLET_SNAPSHOT := "wallet_snapshot"
const AVATAR_CATALOG := "avatar_catalog"
const TABLE_LIST := "table_list"
const TABLE_CREATED := "table_created"
const TABLE_JOINED := "table_joined"
const MOCK_PURCHASE_RESULT := "mock_purchase_result"
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

static func hello(player_name: String = "", player_id: String = "", avatar_id: String = "", auth_provider: String = "local_dev", external_id: String = "") -> Dictionary:
	var data := {"name": player_name, "player_name": player_name}
	if player_id != "":
		data["player_id"] = player_id
	if auth_provider != "":
		data["auth_provider"] = auth_provider
	if external_id != "":
		data["external_id"] = external_id
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

static func get_avatar_catalog() -> Dictionary:
	return _message(GET_AVATAR_CATALOG)

static func buy_avatar(avatar_id: String) -> Dictionary:
	return _message(BUY_AVATAR, {"avatar_id": avatar_id})

static func select_avatar(avatar_id: String) -> Dictionary:
	return _message(SELECT_AVATAR, {"avatar_id": avatar_id})

static func mock_purchase(currency: String, amount: int, source: String = "store_mock") -> Dictionary:
	return _message(MOCK_PURCHASE, {"currency": currency, "amount": amount, "source": source})

static func list_tables() -> Dictionary:
	return _message(LIST_TABLES)

static func create_table(table_name: String = "", config: Dictionary = {}) -> Dictionary:
	var data := {}
	if table_name != "":
		data["table_name"] = table_name
	for key in config.keys():
		data[key] = config[key]
	return _message(CREATE_TABLE, data)

static func join_table(room_id: String) -> Dictionary:
	return _message(JOIN_TABLE, {"room_id": room_id})

static func _message(type_value: String, extra: Dictionary = {}) -> Dictionary:
	var result := {"type": type_value}
	for key in extra.keys():
		result[key] = extra[key]
	return result
