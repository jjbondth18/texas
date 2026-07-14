extends RefCounted
class_name PokerProtocol

const HELLO := "hello"
const CREATE_ROOM := "create_room"
const JOIN_ROOM := "join_room"
const SIT_DOWN := "sit_down"
const LEAVE_SEAT := "leave_seat"
const CASH_OUT := "cash_out"
const READY := "ready"
const RESTART_SESSION := "restart_session"
const START_HAND := "start_hand"
const START_AI_WARMUP := "start_ai_warmup"
const DEV_SIMULATE_REAL_JOIN := "dev_simulate_real_join"
const PLAYER_ACTION := "player_action"
const ADD_TABLE_CHIPS := "add_table_chips"
const GET_PROFILE := "get_profile"
const RENAME_DISPLAY_NAME := "rename_display_name"
const GET_AVATAR_CATALOG := "get_avatar_catalog"
const CLAIM_DAILY_BONUS := "claim_daily_bonus"
const BUY_AVATAR := "buy_avatar"
const SELECT_AVATAR := "select_avatar"
const MOCK_PURCHASE := "mock_purchase"
const UNLOCK_REPLAY := "unlock_replay"
const GET_REPLAY_ACCESS := "get_replay_access"
const IMPORT_LEGACY_REPLAY_ENTITLEMENT := "import_legacy_replay_entitlement"
const LIST_TABLES := "list_tables"
const QUICK_JOIN_TABLE := "quick_join_table"
const CREATE_TABLE := "create_table"
const JOIN_TABLE := "join_table"
const CREATE_PRIVATE_TABLE := "create_private_table"
const JOIN_PRIVATE_TABLE := "join_private_table"
const CREATE_AI_CHALLENGE := "create_ai_challenge"
const TABLE_SNAPSHOT := "table_snapshot"
const PRIVATE_SNAPSHOT := "private_snapshot"
const SIT_DOWN_RESULT := "sit_down_result"
const PROFILE_SNAPSHOT := "profile_snapshot"
const WALLET_SNAPSHOT := "wallet_snapshot"
const DAILY_BONUS_RESULT := "daily_bonus_result"
const AVATAR_CATALOG := "avatar_catalog"
const TABLE_LIST := "table_list"
const QUICK_TABLE_MATCHED := "quick_table_matched"
const TABLE_CREATED := "table_created"
const TABLE_JOINED := "table_joined"
const PRIVATE_TABLE_CREATED := "private_table_created"
const PRIVATE_TABLE_JOINED := "private_table_joined"
const AI_CHALLENGE_CREATED := "ai_challenge_created"
const AI_CHALLENGE_RESULT := "ai_challenge_result"
const MOCK_PURCHASE_RESULT := "mock_purchase_result"
const REPLAY_UNLOCKED := "replay_unlocked"
const REPLAY_ACCESS := "replay_access"
const START_AI_WARMUP_RESULT := "start_ai_warmup_result"
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

static func hello(player_name: String = "", player_id: String = "", avatar_id: String = "", auth_provider: String = "local_dev", external_id: String = "", steam_auth_ticket: String = "", steam_auth_identity: String = "") -> Dictionary:
	var data := {"name": player_name, "player_name": player_name}
	if player_id != "":
		data["player_id"] = player_id
	if auth_provider != "":
		data["auth_provider"] = auth_provider
	if external_id != "":
		data["external_id"] = external_id
		data["external_player_id"] = external_id
		if auth_provider == "local_dev":
			data["dev_player_id"] = external_id
	if avatar_id != "":
		data["avatar_id"] = avatar_id
	if auth_provider == "steam":
		if steam_auth_ticket != "":
			data["steam_auth_ticket"] = steam_auth_ticket
		if steam_auth_identity != "":
			data["steam_auth_identity"] = steam_auth_identity
	return _message(HELLO, data)

static func create_room() -> Dictionary:
	return _message(CREATE_ROOM)

static func join_room(room_id: String) -> Dictionary:
	return _message(JOIN_ROOM, {"room_id": room_id})

static func sit_down(seat_index: int, buy_in: int = 2000) -> Dictionary:
	return _message(SIT_DOWN, {"seat_index": seat_index, "buy_in": buy_in})

static func leave_seat() -> Dictionary:
	return _message(LEAVE_SEAT)

static func cash_out() -> Dictionary:
	return _message(CASH_OUT)

static func ready(is_ready: bool = true) -> Dictionary:
	return _message(READY, {"ready": is_ready})

static func restart_session() -> Dictionary:
	return _message(RESTART_SESSION)

static func start_hand() -> Dictionary:
	return _message(START_HAND)

static func start_ai_warmup(room_id: String) -> Dictionary:
	return _message(START_AI_WARMUP, {"room_id": room_id})

static func dev_simulate_real_join(room_id: String, player_name: String = "DevPlayer2") -> Dictionary:
	return _message(DEV_SIMULATE_REAL_JOIN, {"room_id": room_id, "player_name": player_name})

static func player_action(action: String, amount: int = 0) -> Dictionary:
	var data := {"action": action}
	if amount > 0:
		data["amount"] = amount
	return _message(PLAYER_ACTION, data)

static func add_table_chips(amount: int) -> Dictionary:
	return _message(ADD_TABLE_CHIPS, {"amount": amount})

static func get_profile() -> Dictionary:
	return _message(GET_PROFILE)

static func rename_display_name(display_name: String) -> Dictionary:
	return _message(RENAME_DISPLAY_NAME, {"display_name": display_name})

static func get_avatar_catalog() -> Dictionary:
	return _message(GET_AVATAR_CATALOG)

static func claim_daily_bonus() -> Dictionary:
	return _message(CLAIM_DAILY_BONUS)

static func buy_avatar(avatar_id: String) -> Dictionary:
	return _message(BUY_AVATAR, {"avatar_id": avatar_id})

static func select_avatar(avatar_id: String) -> Dictionary:
	return _message(SELECT_AVATAR, {"avatar_id": avatar_id})

static func mock_purchase(currency: String, amount: int, source: String = "store_mock") -> Dictionary:
	return _message(MOCK_PURCHASE, {"currency": currency, "amount": amount, "source": source})

static func unlock_replay(replay_id: String, replay_type: String, checksum: String = "", key_version: int = 0, algorithm: String = "", storage_mode: String = "") -> Dictionary:
	return _message(UNLOCK_REPLAY, _replay_identity_payload(replay_id, replay_type, checksum, key_version, algorithm, storage_mode))

static func get_replay_access(replay_id: String, replay_type: String, checksum: String = "", key_version: int = 0, algorithm: String = "", storage_mode: String = "") -> Dictionary:
	return _message(GET_REPLAY_ACCESS, _replay_identity_payload(replay_id, replay_type, checksum, key_version, algorithm, storage_mode))

static func import_legacy_replay_entitlement(replay_id: String, replay_type: String, checksum: String = "", key_version: int = 0, algorithm: String = "", storage_mode: String = "") -> Dictionary:
	return _message(IMPORT_LEGACY_REPLAY_ENTITLEMENT, _replay_identity_payload(replay_id, replay_type, checksum, key_version, algorithm, storage_mode))

static func _replay_identity_payload(replay_id: String, replay_type: String, checksum: String, key_version: int, algorithm: String, storage_mode: String) -> Dictionary:
	return {
		"replay_id": replay_id,
		"replay_type": replay_type,
		"checksum": checksum,
		"key_version": key_version,
		"algorithm": algorithm,
		"storage_mode": storage_mode,
	}

static func list_tables() -> Dictionary:
	return _message(LIST_TABLES)

static func quick_join_table(config: Dictionary = {}) -> Dictionary:
	var data := {}
	for key in config.keys():
		data[key] = config[key]
	return _message(QUICK_JOIN_TABLE, data)

static func create_table(table_name: String = "", config: Dictionary = {}) -> Dictionary:
	var data := {}
	if table_name != "":
		data["table_name"] = table_name
	for key in config.keys():
		data[key] = config[key]
	return _message(CREATE_TABLE, data)

static func join_table(room_id: String) -> Dictionary:
	return _message(JOIN_TABLE, {"room_id": room_id})

static func create_private_table(config: Dictionary = {}) -> Dictionary:
	var data := {}
	for key in config.keys():
		data[key] = config[key]
	data["is_public"] = false
	if not data.has("table_type"):
		data["table_type"] = "private_chip"
	return _message(CREATE_PRIVATE_TABLE, data)

static func join_private_table(room_code: String) -> Dictionary:
	return _message(JOIN_PRIVATE_TABLE, {"room_code": room_code.strip_edges().to_upper()})

static func create_ai_challenge(request_id: String = "") -> Dictionary:
	var data := {"challenge_id": "rule_bot_v1"}
	if request_id != "":
		data["request_id"] = request_id
	return _message(CREATE_AI_CHALLENGE, data)

static func _message(type_value: String, extra: Dictionary = {}) -> Dictionary:
	var result := {"type": type_value}
	for key in extra.keys():
		result[key] = extra[key]
	return result
