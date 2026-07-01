extends SceneTree


func _init() -> void:
	var save_source: String = FileAccess.get_file_as_string("res://scripts/services/save_manager.gd")
	var profile_source: String = FileAccess.get_file_as_string("res://scripts/services/profile_service.gd")
	assert(save_source.find("func profile_save_path(save_suffix: String = \"\")") != -1)
	assert(save_source.find("return DEFAULT_SAVE_PATH") != -1)
	assert(save_source.find("return \"user://save_data_%s.json\" % clean_suffix") != -1)
	assert(save_source.find("func load_profile_save(save_suffix: String = \"\")") != -1)
	assert(save_source.find("func save_profile_save(profile: Dictionary, save_suffix: String = \"\")") != -1)
	assert(profile_source.find("IdentityServiceScript.dev_save_suffix()") != -1)
	assert(profile_source.find("SaveManagerScript.load_profile_save(save_suffix)") != -1)
	assert(profile_source.find("SaveManagerScript.save_profile_save(_saved_profile, save_suffix)") != -1)
	print("Save manager dev suffix test passed.")
	quit()
