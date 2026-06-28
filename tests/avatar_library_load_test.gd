extends SceneTree

const AvatarLibraryScript := preload("res://scripts/data/avatar_library.gd")

func _init() -> void:
	var ids: Array[String] = AvatarLibraryScript.load_all_avatars()
	_require(not ids.is_empty(), "avatar library must scan assets/playersAv_cut")
	_require(ids.has("4_05"), "avatar library must include default avatar 4_05")
	_require(AvatarLibraryScript.get_avatar_by_id(ids[0]) != null, "avatar library must load texture by id")
	_require(AvatarLibraryScript.avatar_path(ids[0]).begins_with("res://assets/playersAv_cut/"), "avatar paths must use playersAv_cut")

	print("Avatar library load test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
