extends RefCounted
class_name TableSnapshotService

const HandLifecycleScript := preload("res://scripts/core/hand_lifecycle.gd")

static func build_public_snapshot(state: Dictionary) -> Dictionary:
	return HandLifecycleScript.build_public_snapshot(state)

static func build_private_snapshot(state: Dictionary, player_id: String) -> Dictionary:
	return HandLifecycleScript.build_private_snapshot(state, player_id)
