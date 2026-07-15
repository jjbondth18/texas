extends RefCounted
class_name AvatarLibrary

const AVATAR_ROOT := "res://assets/playersAv_cut/"
const DEFAULT_AVATAR_PRICE_CHIPS := 7500
const DEFAULT_UNLOCKED_CANDIDATES := ["4_05", "1_01", "1_02", "2_01", "6_05"]
const UNLOCK_RULE_AVATARS := {
	"first_session_complete": "1_03",
	"first_hand_win": "3_01",
	"five_hands_won": "7_01",
	"big_pot_5000": "10_03",
	"profitable_session": "8_01",
}
const AVATAR_IDS := [
	"1_01",
	"1_02",
	"1_03",
	"1_04",
	"1_05",
	"1_06",
	"1_07",
	"10_01",
	"10_02",
	"10_03",
	"10_04",
	"10_05",
	"10_06",
	"10_07",
	"11_01",
	"11_02",
	"11_03",
	"11_04",
	"11_05",
	"11_06",
	"11_07",
	"11_08",
	"12_01",
	"12_02",
	"12_03",
	"12_04",
	"12_05",
	"12_06",
	"12_07",
	"12_08",
	"13_01",
	"13_02",
	"13_03",
	"13_04",
	"13_05",
	"13_06",
	"13_07",
	"13_08",
	"2_01",
	"2_04",
	"2_05",
	"2_06",
	"2_07",
	"2_08",
	"3_01",
	"3_02",
	"3_03",
	"3_04",
	"3_05",
	"3_06",
	"3_08",
	"4_01",
	"4_04",
	"4_05",
	"4_06",
	"4_07",
	"4_08",
	"5_01",
	"5_02",
	"5_04",
	"5_05",
	"5_06",
	"5_07",
	"5_08",
	"6_01",
	"6_02",
	"6_03",
	"6_04",
	"6_05",
	"6_06",
	"6_07",
	"6_08",
	"7_01",
	"7_02",
	"7_03",
	"7_04",
	"7_05",
	"7_06",
	"7_07",
	"7_08",
	"8_01",
	"8_02",
	"8_03",
	"8_04",
	"8_05",
	"8_06",
	"8_07",
	"8_08",
	"9_02",
	"9_03",
	"9_04",
	"9_05",
	"9_06",
	"9_07",
]
const DISPLAY_NAME_OVERRIDES := {
	"1_01": "Neon Phantom",
	"1_02": "Cyber Dealer",
	"1_03": "Violet Shark",
	"2_01": "Golden Ace",
	"3_01": "Shadow Player",
	"4_05": "Lucky Fox",
	"6_05": "Royal Spade",
	"7_01": "Crimson Queen",
	"8_01": "Desert Gambler",
	"10_03": "Midnight Rider",
}
const FALLBACK_DISPLAY_NAMES := [
	"Neon Phantom",
	"Cyber Dealer",
	"Violet Shark",
	"Golden Ace",
	"Shadow Player",
	"Lucky Fox",
	"Royal Spade",
	"Crimson Queen",
	"Desert Gambler",
	"Midnight Rider",
	"Diamond Rogue",
	"Velvet Ace",
	"Starlight Jack",
	"Moonlit Caller",
	"Arcade Bluff",
	"Silver River",
]

static var _avatar_ids: Array[String] = []
static var _texture_cache: Dictionary = {}


static func load_all_avatars() -> Array[String]:
	if not _avatar_ids.is_empty():
		return _avatar_ids.duplicate()
	for avatar_id in AVATAR_IDS:
		_avatar_ids.append(String(avatar_id))
	return _avatar_ids.duplicate()


static func avatar_catalog() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for avatar_id in load_all_avatars():
		result.append({
			"avatar_id": avatar_id,
			"display_name": display_name_for_avatar_id(avatar_id),
			"resource_path": avatar_path(avatar_id),
			"currency": "chips",
			"price_chips": price_chips_for_avatar_id(avatar_id),
			"default_unlocked": DEFAULT_UNLOCKED_CANDIDATES.has(avatar_id),
		})
	return result


static func get_avatar_by_id(avatar_id: String) -> Texture2D:
	var resolved_id: String = avatar_id
	if resolved_id == "":
		resolved_id = default_avatar_id()
	if resolved_id == "":
		return null
	if _texture_cache.has(resolved_id):
		return _texture_cache[resolved_id] as Texture2D
	var path: String = avatar_path(resolved_id)
	if not ResourceLoader.exists(path):
		push_warning("[AvatarLibrary] Missing avatar asset: %s" % path)
		return null
	var texture: Texture2D = ResourceLoader.load(path) as Texture2D
	_texture_cache[resolved_id] = texture
	return texture


static func get_random_avatar() -> Texture2D:
	var ids: Array[String] = load_all_avatars()
	if ids.is_empty():
		return null
	var index: int = randi() % ids.size()
	return get_avatar_by_id(ids[index])


static func avatar_path(avatar_id: String) -> String:
	return "%s%s.png" % [AVATAR_ROOT, avatar_id]


static func display_name_for_avatar_id(avatar_id: String) -> String:
	if DISPLAY_NAME_OVERRIDES.has(avatar_id):
		return String(DISPLAY_NAME_OVERRIDES[avatar_id])
	var ids: Array[String] = load_all_avatars()
	var index: int = ids.find(avatar_id)
	if index < 0:
		index = 0
	return String(FALLBACK_DISPLAY_NAMES[index % FALLBACK_DISPLAY_NAMES.size()])


static func price_chips_for_avatar_id(_avatar_id: String) -> int:
	return DEFAULT_AVATAR_PRICE_CHIPS


static func default_avatar_id() -> String:
	var ids: Array[String] = load_all_avatars()
	if ids.is_empty():
		return ""
	return ids[0]


static func default_unlocked_avatar_ids() -> Array[String]:
	var result: Array[String] = []
	for candidate in DEFAULT_UNLOCKED_CANDIDATES:
		var avatar_id: String = String(candidate)
		if ResourceLoader.exists(avatar_path(avatar_id)):
			result.append(avatar_id)
	if result.is_empty():
		var ids: Array[String] = load_all_avatars()
		for index in range(min(ids.size(), 5)):
			result.append(ids[index])
	return result


static func resolve_unlock_avatar_id(rule_id: String, unlocked_ids: Array) -> String:
	var preferred: String = String(UNLOCK_RULE_AVATARS.get(rule_id, ""))
	if preferred != "":
		if ResourceLoader.exists(avatar_path(preferred)):
			return "" if unlocked_ids.has(preferred) else preferred
		for avatar_id in load_all_avatars():
			if not unlocked_ids.has(avatar_id):
				return avatar_id
		return ""
	for avatar_id in load_all_avatars():
		if not unlocked_ids.has(avatar_id):
			return avatar_id
	return ""


static func avatar_id_for_seat(seat_id: int, _is_local: bool = false) -> String:
	var fixed_ids: Dictionary = {
		1: "1_01",
		2: "1_02",
		3: "1_03",
		4: "2_01",
		5: "4_05",
		6: "5_02",
		7: "7_05",
		8: "8_01",
		9: "10_03",
	}
	var candidate: String = String(fixed_ids.get(seat_id, ""))
	if candidate != "" and ResourceLoader.exists(avatar_path(candidate)):
		return candidate
	var ids: Array[String] = load_all_avatars()
	if ids.is_empty():
		return ""
	var safe_seat: int = max(seat_id, 1)
	return ids[(safe_seat - 1) % ids.size()]
