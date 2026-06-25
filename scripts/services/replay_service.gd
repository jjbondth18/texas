extends RefCounted
class_name ReplayService

const ReplayViewModelScript := preload("res://scripts/app/replay_view_model.gd")

func get_replay_view_model() -> Dictionary:
	return ReplayViewModelScript.new().to_dict()
