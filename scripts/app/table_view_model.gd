extends RefCounted
class_name TableViewModel

const TableStateScript := preload("res://scripts/data/table_state.gd")

var table_state

func _init(state = null) -> void:
	table_state = state if state != null else TableStateScript.new()

func to_dict() -> Dictionary:
	return table_state.to_dict()

static func from_dict(data: Dictionary):
	return load("res://scripts/app/table_view_model.gd").new(TableStateScript.from_dict(data))
