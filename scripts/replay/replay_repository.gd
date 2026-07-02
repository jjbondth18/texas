extends RefCounted
class_name ReplayRepository

const REPLAY_DIR := "user://replays"
const INDEX_PATH := "user://replays/replay_index.json"


static func save_hand_record(record: Dictionary) -> bool:
	if not _ensure_replay_dir():
		push_warning("Replay save skipped: could not create user://replays.")
		return false
	var clean_record: Dictionary = record.duplicate(true)
	if str(clean_record.get("ended_at", "")) == "":
		clean_record["ended_at"] = Time.get_datetime_string_from_system(true)
	var file_path: String = _record_file_path(clean_record)
	clean_record["file_path"] = file_path
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_warning("Replay save failed: %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(clean_record, "\t"))
	file.close()
	_update_index(clean_record, file_path)
	return true


static func load_index_entries() -> Array:
	if not FileAccess.file_exists(INDEX_PATH):
		return []
	var file: FileAccess = FileAccess.open(INDEX_PATH, FileAccess.READ)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Array:
		return Array(parsed).duplicate(true)
	return []


static func _update_index(record: Dictionary, file_path: String) -> void:
	var index: Array = load_index_entries()
	var entry: Dictionary = _index_entry(record, file_path)
	var next_index: Array = []
	for item in index:
		var existing: Dictionary = Dictionary(item)
		if str(existing.get("hand_id", "")) == str(entry.get("hand_id", "")) and str(existing.get("room_id", "")) == str(entry.get("room_id", "")):
			continue
		next_index.append(existing)
	next_index.push_front(entry)
	var file: FileAccess = FileAccess.open(INDEX_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Replay index update failed: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(next_index, "\t"))
	file.close()


static func _index_entry(record: Dictionary, file_path: String) -> Dictionary:
	var profit: int = _local_profit(record)
	var sign: String = "+" if profit >= 0 else ""
	var mode_label: String = _mode_label(str(record.get("mode", "")))
	var hand_id: String = str(record.get("hand_id", "hand_000000"))
	return {
		"hand_id": hand_id,
		"room_id": str(record.get("room_id", "")),
		"room_code": str(record.get("room_code", "")),
		"mode": str(record.get("mode", "")),
		"ended_at": str(record.get("ended_at", "")),
		"player_result": "%s%d Chips" % [sign, profit],
		"profit": profit,
		"summary": "%s - %s" % [hand_id, mode_label],
		"file_path": file_path,
	}


static func _local_profit(record: Dictionary) -> int:
	var players: Array = Array(record.get("players", []))
	for player_item in players:
		var player: Dictionary = Dictionary(player_item)
		if bool(player.get("is_local", false)):
			return int(player.get("ending_stack", 0)) - int(player.get("starting_stack", 0))
	if not players.is_empty():
		var first: Dictionary = Dictionary(players[0])
		return int(first.get("ending_stack", 0)) - int(first.get("starting_stack", 0))
	return 0


static func _mode_label(mode: String) -> String:
	match mode:
		"public":
			return "Public Table"
		"private":
			return "Private Room"
		"training":
			return "Training"
		"local_warmup":
			return "Local Warm-up"
	return "Table"


static func _record_file_path(record: Dictionary) -> String:
	var room_id: String = _safe_file_part(str(record.get("room_id", "")))
	var room_code: String = _safe_file_part(str(record.get("room_code", "")))
	var hand_id: String = _safe_file_part(str(record.get("hand_id", "hand_000000")))
	var mode: String = str(record.get("mode", "public"))
	var prefix: String = room_id
	if mode == "private" and room_code != "":
		prefix = "private_%s" % room_code
	elif mode == "training":
		prefix = "training"
	elif mode == "local_warmup":
		prefix = "warmup"
	elif prefix == "":
		prefix = mode
	return "%s/%s_%s.json" % [REPLAY_DIR, prefix, hand_id]


static func _safe_file_part(value: String) -> String:
	var safe: String = value.strip_edges()
	if safe == "":
		return ""
	for token_item in ["\\", "/", ":", "*", "?", "\"", "<", ">", "|", " "]:
		var token: String = str(token_item)
		safe = safe.replace(token, "_")
	return safe


static func _ensure_replay_dir() -> bool:
	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		return false
	if dir.dir_exists("replays"):
		return true
	return dir.make_dir_recursive("replays") == OK
