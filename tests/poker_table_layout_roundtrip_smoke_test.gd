extends SceneTree

const PokerTableScene := preload("res://scenes/screens/poker_table_screen.tscn")
const LayoutSchema := preload("res://scripts/dev/poker_table_layout_schema.gd")

const TEST_BOTTOM_HUD_RECT := Rect2(Vector2(360, 610), Vector2(1600, 180))

var _original_user_config_exists := false
var _original_user_config_text := ""

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_preserve_user_config()
	var items := LayoutSchema.DEFAULT_ITEMS.duplicate(true)
	items["bottom_hud"] = LayoutSchema.rect_to_dict(TEST_BOTTOM_HUD_RECT)
	var save_error := LayoutSchema.save_user_config(items)
	if save_error != OK:
		push_error("Failed to save test layout config: %s" % save_error)
		_restore_user_config()
		quit(1)
		return

	root.size = Vector2i(1920, 1080)
	var scene: Node = PokerTableScene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var bottom_hud := scene.get_node("TableUIRoot/BottomPlayerPanel") as Control
	var passed := _rects_close(Rect2(bottom_hud.position, bottom_hud.size), TEST_BOTTOM_HUD_RECT)
	_restore_user_config()
	if not passed:
		push_error("Bottom HUD did not apply saved layout. Expected %s, got %s" % [TEST_BOTTOM_HUD_RECT, Rect2(bottom_hud.position, bottom_hud.size)])
		quit(1)
		return

	print("Poker table layout roundtrip smoke test passed.")
	quit(0)

func _preserve_user_config() -> void:
	_original_user_config_exists = FileAccess.file_exists(LayoutSchema.USER_CONFIG_PATH)
	if not _original_user_config_exists:
		return
	var file := FileAccess.open(LayoutSchema.USER_CONFIG_PATH, FileAccess.READ)
	if file != null:
		_original_user_config_text = file.get_as_text()

func _restore_user_config() -> void:
	if _original_user_config_exists:
		var file := FileAccess.open(LayoutSchema.USER_CONFIG_PATH, FileAccess.WRITE)
		if file != null:
			file.store_string(_original_user_config_text)
	elif FileAccess.file_exists(LayoutSchema.USER_CONFIG_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(LayoutSchema.USER_CONFIG_PATH))

func _rects_close(actual: Rect2, expected: Rect2) -> bool:
	return actual.position.distance_to(expected.position) < 0.1 and actual.size.distance_to(expected.size) < 0.1
