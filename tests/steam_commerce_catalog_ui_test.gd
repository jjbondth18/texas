extends SceneTree

func _init() -> void:
	var home_source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var catalog_source := FileAccess.get_file_as_string("res://server/src/store_catalog.ts")
	assert(home_source.contains('packs_tab.text = "PACKS"'))
	assert(not home_source.contains('tab_name in ["CHIPS", "GEMS", "BUNDLES"]'))
	assert(home_source.contains("_store_catalog_grid.columns = 2"))
	assert(home_source.contains('chips.text = "%s CHIPS"'))
	assert(home_source.contains('gems.text = "%s GEMS"'))
	assert(home_source.contains("STORE_BUNDLE_IMAGES.get(image_key"))
	assert(home_source.contains("TextureRect.STRETCH_KEEP_ASPECT_CENTERED"))
	assert(home_source.contains('fallback.text = "Bundle artwork\\nunavailable"'))
	assert(home_source.contains("BUY WITH STEAM"))
	assert(home_source.contains("Store is temporarily unavailable."))
	assert(not home_source.contains("func _add_store_currency_column"))
	for package_id in ["starter_pack", "club_pack", "pro_pack", "high_roller_pack"]:
		assert(catalog_source.contains('"%s"' % package_id))
	for removed_id in ["chip_starter", "gem_pouch", "rookie_bundle"]:
		assert(not catalog_source.contains('"%s"' % removed_id))
	quit()
