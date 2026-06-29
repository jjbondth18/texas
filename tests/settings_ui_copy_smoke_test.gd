extends SceneTree

const HomeScene := preload("res://scenes/screens/home_lobby_screen.tscn")
const SettingsServiceScript := preload("res://scripts/services/settings_service.gd")

func _initialize() -> void:
	SettingsServiceScript.reset_for_tests("user://test_settings_ui_copy.cfg")
	var home := HomeScene.instantiate()
	root.add_child(home)
	await process_frame
	await process_frame
	home.call("set_state", 5, false)
	await process_frame

	var visible_copy := _collect_visible_copy(home)
	for required in ["SETTINGS", "AUDIO", "GAMEPLAY", "DISPLAY", "ACCOUNT & PRIVACY", "ADVANCED"]:
		_require(visible_copy.contains(required), "Settings panel must include %s" % required)
	for required in ["Cloud Sync", "Account Binding", "Coming Soon", "Future Server: Coming Soon"]:
		_require(visible_copy.contains(required), "Settings panel must include placeholder copy: %s" % required)
	_require(not visible_copy.contains("Real Server Enabled"), "Settings copy must not imply a real server is enabled")
	_require(not visible_copy.contains("Real Cloud Sync"), "Settings copy must not imply real cloud sync is enabled")
	_require(not visible_copy.contains("Real Payment"), "Settings copy must not imply real payment")

	home.queue_free()
	SettingsServiceScript.reset_for_tests("user://test_settings_ui_copy.cfg")
	print("Settings UI copy smoke test passed.")
	quit(0)

func _collect_visible_copy(node: Node) -> String:
	var parts: Array[String] = []
	_collect_visible_copy_into(node, parts)
	return "\n".join(parts)

func _collect_visible_copy_into(node: Node, parts: Array[String]) -> void:
	if node is CanvasItem and not (node as CanvasItem).visible:
		return
	if node is Label:
		parts.append((node as Label).text)
	elif node is Button:
		parts.append((node as Button).text)
	elif node is OptionButton:
		var option := node as OptionButton
		for i in range(option.get_item_count()):
			parts.append(option.get_item_text(i))
	for child in node.get_children():
		_collect_visible_copy_into(child, parts)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
