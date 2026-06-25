extends RefCounted
class_name LobbyMode

var id := ""
var title := ""
var subtitle := ""
var image := ""
var route := ""
var enabled := true

func _init(mode_id: String = "", mode_title: String = "", mode_subtitle: String = "", image_path: String = "", is_enabled: bool = true, route_id: String = "") -> void:
	id = mode_id
	title = mode_title
	subtitle = mode_subtitle
	image = image_path
	enabled = is_enabled
	route = route_id if route_id != "" else mode_id

func to_dict() -> Dictionary:
	return {
		"id": id,
		"title": title,
		"subtitle": subtitle,
		"image": image,
		"route": route,
		"enabled": enabled,
	}

static func from_dict(data: Dictionary):
	return load("res://scripts/data/lobby_mode.gd").new(
		String(data.get("id", "")),
		String(data.get("title", "")),
		String(data.get("subtitle", "")),
		String(data.get("image", "")),
		bool(data.get("enabled", true)),
		String(data.get("route", data.get("id", "")))
	)
