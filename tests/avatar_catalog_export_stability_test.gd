extends SceneTree

const AvatarLibraryScript := preload("res://scripts/data/avatar_library.gd")

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/data/avatar_library.gd")
	_require(source.find("DirAccess.open") == -1, "avatar catalog should not depend on DirAccess enumeration")
	var ids := AvatarLibraryScript.load_all_avatars()
	_require(ids.size() == 94, "avatar catalog should contain the 94 exported avatar PNGs")
	var catalog := AvatarLibraryScript.avatar_catalog()
	_require(catalog.size() == ids.size(), "avatar catalog entries should match avatar ids")
	for entry_value in catalog:
		var entry := Dictionary(entry_value)
		var avatar_id := str(entry.get("avatar_id", ""))
		var resource_path := str(entry.get("resource_path", ""))
		_require(avatar_id != "", "avatar entry should have avatar_id")
		_require(resource_path != "", "avatar entry should have resource_path")
		_require(ResourceLoader.exists(resource_path), "avatar resource should be loadable: %s" % resource_path)
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
