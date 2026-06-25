extends RefCounted
class_name RoomBrowserViewModel

const RoomInfoScript := preload("res://scripts/data/room_info.gd")

var rooms: Array = []

func _init(room_list: Array = []) -> void:
	rooms = room_list.duplicate()

func to_dict() -> Dictionary:
	var room_data: Array[Dictionary] = []
	for room in rooms:
		room_data.append(room.to_dict())
	return {
		"rooms": room_data,
	}

static func from_dict(data: Dictionary):
	var parsed_rooms: Array = []
	for room_data in Array(data.get("rooms", [])):
		parsed_rooms.append(RoomInfoScript.from_dict(room_data))
	return load("res://scripts/app/room_browser_view_model.gd").new(parsed_rooms)
