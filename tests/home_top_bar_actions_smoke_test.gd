extends SceneTree

const HomeScene := preload("res://scenes/screens/home_lobby_screen.tscn")

func _initialize() -> void:
	var home := HomeScene.instantiate()
	root.add_child(home)
	await process_frame
	await process_frame

	var top_bar := home.get_node_or_null("LobbyUIRoot/TopBar")
	_require(top_bar != null, "TopBar must exist")
	var top_buttons := _collect_button_texts(top_bar)
	_require(top_buttons == ["SOCIAL", "HELP", "EXIT"], "TopBar must only show SOCIAL / HELP / EXIT")
	for removed in ["+", "FR", "MSG", "SET", "SETTINGS"]:
		_require(not top_buttons.has(removed), "TopBar must not show %s" % removed)

	var social_button := top_bar.get_node_or_null("HBoxContainer/SocialButton") as Button
	_require(social_button != null, "Social button must exist")
	social_button.emit_signal("pressed")
	await process_frame
	var social_copy := _collect_visible_copy(home)
	_require(social_copy.contains("SOCIAL"), "Social panel must show title")
	_require(social_copy.contains("Friends and messages will be available in a future update."), "Social panel must explain future friends and messages")

	var help_button := top_bar.get_node_or_null("HBoxContainer/HelpButton") as Button
	_require(help_button != null, "Help button must exist")
	help_button.emit_signal("pressed")
	await process_frame
	var help_copy := _collect_visible_copy(home)
	for section in ["HELP & RULES", "Poker Basics", "Hand Rankings", "Game Modes", "Chips & Gems", "Table Rules"]:
		_require(help_copy.contains(section), "Help panel must include %s" % section)
	_require(help_copy.contains("Add Chips moves chips from wallet to table. It is not a purchase."), "Help must explain Add Chips is not a purchase")
	_require(help_copy.contains("Gem Match is Coming Soon and requires secure server matchmaking."), "Help must explain Gem Match server requirement")

	home.queue_free()
	print("Home top bar actions smoke test passed.")
	quit(0)

func _collect_button_texts(node: Node) -> Array[String]:
	var output: Array[String] = []
	_collect_button_texts_into(node, output)
	return output

func _collect_button_texts_into(node: Node, output: Array[String]) -> void:
	if node is Button:
		output.append((node as Button).text)
	for child in node.get_children():
		_collect_button_texts_into(child, output)

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
	for child in node.get_children():
		_collect_visible_copy_into(child, parts)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
