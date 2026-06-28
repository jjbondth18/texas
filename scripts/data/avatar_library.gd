extends RefCounted
class_name AvatarLibrary

const AVATAR_ROOT := "res://assets/playersAv_cut/"

static var _avatar_ids: Array[String] = []
static var _texture_cache: Dictionary = {}


static func load_all_avatars() -> Array[String]:
	if not _avatar_ids.is_empty():
		return _avatar_ids.duplicate()
	var dir: DirAccess = DirAccess.open(AVATAR_ROOT)
	if dir == null:
		push_warning("[AvatarLibrary] Avatar directory not found: %s" % AVATAR_ROOT)
		return []
	dir.list_dir_begin()
	while true:
		var file_name: String = dir.get_next()
		if file_name == "":
			break
		if dir.current_is_dir():
			continue
		if file_name.get_extension().to_lower() != "png":
			continue
		_avatar_ids.append(file_name.get_basename())
	dir.list_dir_end()
	_avatar_ids.sort()
	return _avatar_ids.duplicate()


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
	var texture: Texture2D = load(path) as Texture2D
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


static func default_avatar_id() -> String:
	var ids: Array[String] = load_all_avatars()
	if ids.is_empty():
		return ""
	return ids[0]


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
