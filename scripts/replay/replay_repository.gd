extends RefCounted
class_name ReplayRepository

const REPLAY_DIR := "user://replays"
const INDEX_PATH := "user://replays/replay_index.json"
const OFFICIAL_ENCRYPTED_MODE := "official_encrypted"
const ENCRYPTED_ALGORITHM := "AES-256-CBC-HMAC-SHA256"


static func save_encrypted_delivery(delivery: Dictionary) -> bool:
	if not _ensure_replay_dir():
		push_warning("Encrypted replay save skipped: could not create user://replays.")
		return false
	var replay_id: String = _safe_file_part(str(delivery.get("replay_id", "")))
	if replay_id == "":
		push_warning("Encrypted replay save skipped: missing replay_id.")
		return false
	var replay_dir: String = "%s/%s" % [REPLAY_DIR, replay_id]
	if not _ensure_dir_path(replay_dir):
		push_warning("Encrypted replay save skipped: could not create %s." % replay_dir)
		return false
	var metadata: Dictionary = Dictionary(delivery.get("metadata", {})).duplicate(true)
	var public_preview: Dictionary = Dictionary(delivery.get("public_preview", {})).duplicate(true)
	var encrypted_blob: String = str(delivery.get("encrypted_private_blob", ""))
	if metadata.is_empty() or encrypted_blob == "":
		push_warning("Encrypted replay save skipped: incomplete delivery for %s." % replay_id)
		return false
	metadata["replay_id"] = str(metadata.get("replay_id", replay_id))
	metadata["storage_mode"] = str(metadata.get("storage_mode", "official_encrypted"))
	metadata["locked"] = bool(metadata.get("locked", true))
	metadata["checksum"] = str(delivery.get("checksum", metadata.get("checksum", "")))
	metadata["key_version"] = int(delivery.get("key_version", metadata.get("key_version", 1)))
	var metadata_path: String = "%s/metadata.json" % replay_dir
	var preview_path: String = "%s/public_preview.json" % replay_dir
	var private_path: String = "%s/private.enc" % replay_dir
	metadata["file_path"] = metadata_path
	metadata["public_preview_path"] = preview_path
	metadata["private_blob_path"] = private_path
	if not _write_json_file(metadata_path, metadata):
		return false
	if not _write_json_file(preview_path, public_preview):
		return false
	if not _write_text_file(private_path, encrypted_blob):
		return false
	_update_index(metadata, metadata_path)
	return true


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


static func load_hand_record(file_path: String) -> Dictionary:
	if file_path == "" or not FileAccess.file_exists(file_path):
		return {}
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		var record: Dictionary = Dictionary(parsed).duplicate(true)
		if is_official_encrypted_record(record):
			return _load_encrypted_preview_record(record, file_path)
		return record
	return {}


static func is_official_encrypted_record(record: Dictionary) -> bool:
	return str(record.get("storage_mode", "")) == OFFICIAL_ENCRYPTED_MODE


static func is_official_encrypted_entry(entry: Dictionary) -> bool:
	return str(entry.get("storage_mode", "")) == OFFICIAL_ENCRYPTED_MODE


static func has_unlock_cache(record_or_entry: Dictionary) -> bool:
	var replay_id: String = _safe_file_part(str(record_or_entry.get("replay_id", "")))
	var cache_path: String = _unlock_cache_path(record_or_entry)
	if replay_id == "" or cache_path == "":
		return false
	if not FileAccess.file_exists(cache_path):
		return false
	var cache: Dictionary = _read_json_file(cache_path)
	return bool(cache.get("unlocked", false)) and str(cache.get("replay_id", "")) == replay_id and str(cache.get("replay_key", "")) != ""


static func save_unlock_cache(record_or_entry: Dictionary, replay_key: String, key_version: int, checksum: String) -> bool:
	var replay_id: String = _safe_file_part(str(record_or_entry.get("replay_id", "")))
	if replay_id == "" or replay_key == "":
		return false
	var replay_dir: String = _replay_dir_for_record(record_or_entry)
	if replay_dir == "" or not _ensure_dir_path(replay_dir):
		return false
	var cache := {
		"replay_id": replay_id,
		"unlocked": true,
		"replay_key": replay_key,
		"key_version": key_version,
		"checksum": checksum,
		"unlocked_at": Time.get_datetime_string_from_system(true),
		"authority": "server",
	}
	return _write_json_file("%s/unlock.json" % replay_dir, cache)


static func load_unlocked_encrypted_record(record_or_entry: Dictionary, replay_key: String = "") -> Dictionary:
	if not is_official_encrypted_record(record_or_entry) and not is_official_encrypted_entry(record_or_entry):
		return load_hand_record(str(record_or_entry.get("file_path", "")))
	var key: String = replay_key
	if key == "":
		key = str(_read_json_file(_unlock_cache_path(record_or_entry)).get("replay_key", ""))
	if key == "":
		return {}
	var private_path: String = str(record_or_entry.get("private_blob_path", ""))
	if private_path == "":
		private_path = "%s/private.enc" % _replay_dir_for_record(record_or_entry)
	if private_path == "" or not FileAccess.file_exists(private_path):
		push_warning("Replay decrypt failed: missing local private.enc.")
		return {"error": "missing_private_blob"}
	var encrypted_blob: String = _read_text_file(private_path)
	var expected_checksum: String = str(record_or_entry.get("checksum", ""))
	var actual_checksum: String = _sha256_hex(encrypted_blob)
	if expected_checksum != "" and actual_checksum != expected_checksum:
		push_warning("Replay decrypt failed: checksum mismatch for %s." % str(record_or_entry.get("replay_id", "")))
		return {"error": "replay_checksum_mismatch"}
	var decrypted: Dictionary = _decrypt_private_blob(encrypted_blob, key)
	if decrypted.is_empty():
		return {"error": "replay_decrypt_failed"}
	decrypted["file_path"] = str(record_or_entry.get("file_path", ""))
	decrypted["storage_mode"] = OFFICIAL_ENCRYPTED_MODE
	decrypted["locked"] = false
	return decrypted


static func _load_encrypted_preview_record(metadata: Dictionary, metadata_path: String) -> Dictionary:
	var preview_path: String = str(metadata.get("public_preview_path", ""))
	if preview_path == "":
		preview_path = "%s/public_preview.json" % metadata_path.get_base_dir()
	var preview: Dictionary = _read_json_file(preview_path)
	var merged: Dictionary = metadata.duplicate(true)
	for key in preview.keys():
		if not merged.has(key):
			merged[key] = preview[key]
	merged["file_path"] = metadata_path
	merged["public_preview_path"] = preview_path
	if not merged.has("private_blob_path"):
		merged["private_blob_path"] = "%s/private.enc" % metadata_path.get_base_dir()
	merged["locked"] = not has_unlock_cache(merged)
	return merged


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
	var mode: String = str(record.get("mode", ""))
	var currency: String = str(record.get("currency", "gems" if str(record.get("table_type", "")).ends_with("_gem") else "chips"))
	var unit_label: String = "Gems" if currency in ["gem", "gems"] else "Chips"
	var mode_label: String = _mode_label(str(record.get("mode", "")))
	var hand_id: String = str(record.get("hand_id", "hand_000000"))
	var result_text: String = "Practice" if mode in ["training", "local_warmup"] else "%s%d %s" % [sign, profit, unit_label]
	return {
		"replay_id": str(record.get("replay_id", "")),
		"hand_id": hand_id,
		"room_id": str(record.get("room_id", "")),
		"room_code": str(record.get("room_code", "")),
		"mode": mode,
		"currency": currency,
		"dealer_id": str(record.get("dealer_id", "")),
		"ended_at": str(record.get("ended_at", "")),
		"player_result": result_text,
		"profit": profit,
		"summary": _summary_text(record, hand_id, mode_label),
		"file_path": file_path,
		"public_preview_path": str(record.get("public_preview_path", "")),
		"private_blob_path": str(record.get("private_blob_path", "")),
		"storage_mode": str(record.get("storage_mode", "")),
		"checksum": str(record.get("checksum", "")),
		"key_version": int(record.get("key_version", 0)),
		"locked": bool(record.get("locked", false)),
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


static func _summary_text(record: Dictionary, hand_id: String, mode_label: String) -> String:
	var results: Dictionary = Dictionary(record.get("results", {}))
	var winners: Array = Array(results.get("winners", []))
	var winner_text: String = "No winner"
	if not winners.is_empty():
		var winner_names: Array[String] = []
		for winner_item in winners:
			var winner: Dictionary = Dictionary(winner_item)
			var winner_name: String = str(winner.get("winner_player_id", ""))
			if winner_name == "":
				winner_name = "Seat %d" % int(winner.get("winner_seat", -1))
			winner_names.append(winner_name)
		winner_text = ", ".join(winner_names)
	var final_pot: int = int(results.get("final_pot", 0))
	return "%s - %s - Winner: %s - Pot %d" % [hand_id, mode_label, winner_text, final_pot]


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


static func _ensure_dir_path(path: String) -> bool:
	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		return false
	return dir.make_dir_recursive(path.replace("user://", "")) == OK


static func _write_json_file(path: String, data: Dictionary) -> bool:
	return _write_text_file(path, JSON.stringify(data, "\t"))


static func _write_text_file(path: String, text: String) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("Replay file write failed: %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(text)
	file.close()
	return true


static func _read_json_file(path: String) -> Dictionary:
	if path == "" or not FileAccess.file_exists(path):
		return {}
	var text: String = _read_text_file(path)
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return Dictionary(parsed).duplicate(true)
	return {}


static func _read_text_file(path: String) -> String:
	if path == "" or not FileAccess.file_exists(path):
		return ""
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


static func _replay_dir_for_record(record_or_entry: Dictionary) -> String:
	var private_path: String = str(record_or_entry.get("private_blob_path", ""))
	if private_path != "":
		return private_path.get_base_dir()
	var file_path: String = str(record_or_entry.get("file_path", ""))
	if file_path != "":
		return file_path.get_base_dir()
	var replay_id: String = _safe_file_part(str(record_or_entry.get("replay_id", "")))
	if replay_id != "":
		return "%s/%s" % [REPLAY_DIR, replay_id]
	return ""


static func _unlock_cache_path(record_or_entry: Dictionary) -> String:
	var replay_dir: String = _replay_dir_for_record(record_or_entry)
	if replay_dir == "":
		return ""
	return "%s/unlock.json" % replay_dir


static func _sha256_hex(text: String) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(text.to_utf8_buffer())
	return context.finish().hex_encode()


static func _decrypt_private_blob(encrypted_blob: String, replay_key: String) -> Dictionary:
	var envelope: Variant = JSON.parse_string(encrypted_blob)
	if not (envelope is Dictionary):
		return {}
	var data: Dictionary = Dictionary(envelope)
	if str(data.get("algorithm", "")) != ENCRYPTED_ALGORITHM:
		push_warning("Replay decrypt failed: unsupported algorithm %s." % str(data.get("algorithm", "")))
		return {}
	var key: PackedByteArray = Marshalls.base64_to_raw(replay_key)
	var iv: PackedByteArray = Marshalls.base64_to_raw(str(data.get("iv", "")))
	var ciphertext: PackedByteArray = Marshalls.base64_to_raw(str(data.get("ciphertext", "")))
	var expected_mac: PackedByteArray = Marshalls.base64_to_raw(str(data.get("mac", "")))
	if key.size() != 32 or iv.size() != 16 or ciphertext.is_empty() or expected_mac.size() != 32:
		return {}
	var enc_key: PackedByteArray = _derive_replay_subkey(key, "texas-replay-enc-v1")
	var mac_key: PackedByteArray = _derive_replay_subkey(key, "texas-replay-mac-v1")
	var mac_input := PackedByteArray()
	mac_input.append_array(iv)
	mac_input.append_array(ciphertext)
	var actual_mac: PackedByteArray = Crypto.new().hmac_digest(HashingContext.HASH_SHA256, mac_key, mac_input)
	if not _constant_time_equal(actual_mac, expected_mac):
		push_warning("Replay decrypt failed: HMAC mismatch.")
		return {}
	var aes := AESContext.new()
	if aes.start(AESContext.MODE_CBC_DECRYPT, enc_key, iv) != OK:
		return {}
	var padded: PackedByteArray = aes.update(ciphertext)
	aes.finish()
	var plaintext_bytes: PackedByteArray = _strip_pkcs7_padding(padded)
	if plaintext_bytes.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(plaintext_bytes.get_string_from_utf8())
	if parsed is Dictionary:
		return Dictionary(parsed).duplicate(true)
	return {}


static func _derive_replay_subkey(root_key: PackedByteArray, label: String) -> PackedByteArray:
	return Crypto.new().hmac_digest(HashingContext.HASH_SHA256, root_key, label.to_utf8_buffer())


static func _strip_pkcs7_padding(data: PackedByteArray) -> PackedByteArray:
	if data.is_empty():
		return PackedByteArray()
	var pad: int = int(data[data.size() - 1])
	if pad <= 0 or pad > 16 or pad > data.size():
		return PackedByteArray()
	for index in range(data.size() - pad, data.size()):
		if int(data[index]) != pad:
			return PackedByteArray()
	return data.slice(0, data.size() - pad)


static func _constant_time_equal(a: PackedByteArray, b: PackedByteArray) -> bool:
	if a.size() != b.size():
		return false
	var diff := 0
	for index in range(a.size()):
		diff |= int(a[index]) ^ int(b[index])
	return diff == 0
