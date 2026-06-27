extends RefCounted
class_name PokerTableLayoutSchema

const VERSION := 1
const DESIGN_SIZE := Vector2(2560, 1000)
const USER_CONFIG_PATH := "user://poker_table_layout_config.json"
const DEFAULT_CONFIG_PATH := "res://docs/frontend/poker_table_layout_config.default.json"

const TARGET_IDS := [
	"seat_1",
	"seat_2",
	"seat_3",
	"seat_4",
	"seat_5_local",
	"seat_6",
	"seat_7",
	"seat_8",
	"seat_9",
	"left_panel",
	"right_panel",
	"bottom_hud",
	"pot_display",
	"community_board",
	"dealer_indicator",
]

const DEFAULT_ITEMS := {
	"seat_1": {"x": 1580, "y": 250, "w": 180, "h": 90},
	"seat_2": {"x": 1880, "y": 340, "w": 180, "h": 90},
	"seat_3": {"x": 2030, "y": 520, "w": 180, "h": 90},
	"seat_4": {"x": 1760, "y": 700, "w": 180, "h": 90},
	"seat_5_local": {"x": 1180, "y": 710, "w": 220, "h": 100},
	"seat_6": {"x": 720, "y": 700, "w": 180, "h": 90},
	"seat_7": {"x": 410, "y": 520, "w": 180, "h": 90},
	"seat_8": {"x": 560, "y": 340, "w": 180, "h": 90},
	"seat_9": {"x": 900, "y": 250, "w": 180, "h": 90},
	"left_panel": {"x": 0, "y": 160, "w": 320, "h": 760},
	"right_panel": {"x": 2240, "y": 160, "w": 320, "h": 760},
	"bottom_hud": {"x": 280, "y": 760, "w": 1880, "h": 190},
	"pot_display": {"x": 1100, "y": 360, "w": 360, "h": 90},
	"community_board": {"x": 930, "y": 455, "w": 700, "h": 130},
	"dealer_indicator": {"x": 1200, "y": 220, "w": 160, "h": 50},
}

static func empty_config() -> Dictionary:
	return {
		"version": VERSION,
		"design_size": {"w": DESIGN_SIZE.x, "h": DESIGN_SIZE.y},
		"items": {},
	}

static func default_config() -> Dictionary:
	var config := empty_config()
	config["items"] = DEFAULT_ITEMS.duplicate(true)
	return config

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
		Vector2(float(data.get("w", 20.0)), float(data.get("h", 20.0)))
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

static func load_default_config_file() -> Dictionary:
	if not FileAccess.file_exists(DEFAULT_CONFIG_PATH):
		return default_config()
	var file := FileAccess.open(DEFAULT_CONFIG_PATH, FileAccess.READ)
	if file == null:
		return default_config()
	var config := deserialize(file.get_as_text())
	if Dictionary(config.get("items", {})).is_empty():
		return default_config()
	return config

static func load_runtime_config() -> Dictionary:
	if FileAccess.file_exists(USER_CONFIG_PATH):
		var user_config := load_user_config()
		if not Dictionary(user_config.get("items", {})).is_empty():
			return {
				"source": "user",
				"path": USER_CONFIG_PATH,
				"config": user_config,
			}
	var default_config_file := load_default_config_file()
	return {
		"source": "default",
		"path": DEFAULT_CONFIG_PATH,
		"config": default_config_file,
	}

static func save_user_config(items: Dictionary) -> Error:
	var file := FileAccess.open(USER_CONFIG_PATH, FileAccess.WRITE)
	if file == null:
		return ERR_CANT_OPEN
	file.store_string(serialize(items))
	return OK

static func merged_items_with_defaults(config: Dictionary) -> Dictionary:
	var items := DEFAULT_ITEMS.duplicate(true)
	var config_items := Dictionary(config.get("items", {}))
	for id in config_items.keys():
		if DEFAULT_ITEMS.has(id):
			items[id] = Dictionary(config_items[id]).duplicate(true)
	return items
