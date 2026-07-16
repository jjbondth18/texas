extends SceneTree

func _init() -> void:
	var preset := FileAccess.get_file_as_string("res://export_presets.cfg")
	for required_filter in [
		"build/*",
		"build/**/*",
		"docs/*",
		"docs/**/*",
		"server/*",
		"server/**/*",
		"tests/*",
		"tests/**/*",
		"dev/*",
		"dev/**/*",
		"screenshots/*",
		"screenshots/**/*",
		".env",
		".env.*",
		"**/.env",
		"**/.env.*",
		"*.sqlite",
		"**/*.sqlite",
		"*.db",
		"**/*.db",
		"*.log",
		"**/*.log",
	]:
		assert(preset.contains(required_filter), "missing export exclusion: %s" % required_filter)
	for runtime_filter in [
		"assets/playersAv_cut/**/*.png",
		"assets/croupier/processed/**/*.png",
		"assets/card/**/*.png",
		"assets/ui/cardback/**/*.png",
	]:
		assert(preset.contains(runtime_filter), "missing runtime resource inclusion: %s" % runtime_filter)
	quit()
