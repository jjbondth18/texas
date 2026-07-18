extends SceneTree

const EXPECTED := {
	"starter_pack": "res://assets/store/bundles/starter_pack.png",
	"club_pack": "res://assets/store/bundles/club_pack.png",
	"pro_pack": "res://assets/store/bundles/pro_pack.png",
	"high_roller_pack": "res://assets/store/bundles/high_roller_pack.png",
}

func _init() -> void:
	var home_source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var export_source := FileAccess.get_file_as_string("res://export_presets.cfg")
	for package_id in EXPECTED:
		var path: String = EXPECTED[package_id]
		assert(FileAccess.file_exists(path))
		var image := Image.new()
		assert(image.load(path) == OK)
		assert(image.get_width() == 600)
		assert(image.get_height() == 600)
		assert(home_source.contains('"%s": "%s"' % [package_id, path]))
	assert(home_source.contains("card.custom_minimum_size = Vector2(420, 190)"))
	assert(home_source.contains("art_frame.custom_minimum_size = Vector2(160, 160)"))
	assert(home_source.contains("var card_row := HBoxContainer.new()"))
	assert(export_source.contains("assets/store/bundles/*.png"))
	assert(export_source.contains("assets/chipgem.png"))
	quit()
