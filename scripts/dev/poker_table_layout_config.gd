extends RefCounted
class_name PokerTableLayoutConfig

const VERSION := 1
const DESIGN_SIZE := Vector2(2560, 1000)
const USER_CONFIG_PATH := "user://poker_table_layout_config.json"

static func empty_config() -> Dictionary:
	return {
		"version": VERSION,
		"design_size": {"w": DESIGN_SIZE.x, "h": DESIGN_SIZE.y},
		"items": {},
	}

static func rect_to_dict(rect: Rect2) -> Dictionary:
	return {
		"x": rect.position.x,
		"y": rect.position.y,
		"w": rect.size.x,
		"h": rect.size.y,
	}

static func dict_to_rect(data: Dictionary) -> Rect2:
	return Rect2(
		Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0))),
		Vector2(float(data.get("w", 0.0)), float(data.get("h", 0.0)))
	)

static func serialize(items: Dictionary) -> String:
	var config := empty_config()
	config["items"] = items.duplicate(true)
	return JSON.stringify(config, "\t")

static func deserialize(text: String) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(text) == OK and parser.data is Dictionary:
		var config := Dictionary(parser.data)
		if not config.has("items") or not config["items"] is Dictionary:
			config["items"] = {}
		return config
	return empty_config()

static func load_user_config() -> Dictionary:
	if not FileAccess.file_exists(USER_CONFIG_PATH):
		return empty_config()
	var file := FileAccess.open(USER_CONFIG_PATH, FileAccess.READ)
	if file == null:
		return empty_config()
	return deserialize(file.get_as_text())

static func save_user_config(items: Dictionary) -> Error:
	var file := FileAccess.open(USER_CONFIG_PATH, FileAccess.WRITE)
	if file == null:
		return ERR_CANT_OPEN
	file.store_string(serialize(items))
	return OK
