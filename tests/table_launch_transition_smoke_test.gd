extends SceneTree

const HomeScene := preload("res://scenes/screens/home_lobby_screen.tscn")
const PublicTableRegistryScript := preload("res://scripts/services/public_table_registry.gd")

func _initialize() -> void:
	PublicTableRegistryScript.reset()
	var home := HomeScene.instantiate()
	root.add_child(home)
	await process_frame
	await process_frame

	home.call("_on_mode_selected", "quick_play")
	await process_frame
	home.call("_start_quick_play_from_setup")
	_require(bool(home.get("_is_launching_table")), "Quick Chip must trigger the launch transition")
	var label: Label = home.get("_launch_transition_label") as Label
	_require(label != null and label.text.contains("Finding a public chip table"), "Quick Chip transition text must describe public table finding")
	home.call("_finish_table_launch_transition")

	PublicTableRegistryScript.create_public_table({"table_id": "transition_join_table", "current_players": 2})
	home.call("_on_join_pressed", "transition_join_table")
	_require(bool(home.get("_is_launching_table")), "Table Browser join must trigger the launch transition")
	_require(label.text.contains("Joining public table"), "Table Browser join transition text must describe joining")
	home.call("_finish_table_launch_transition")

	home.call("_on_mode_selected", "training")
	_require(bool(home.get("_is_launching_table")), "Training must trigger the launch transition")
	_require(label.text.contains("Preparing AI training table"), "Training transition text must describe AI training")
	home.call("_finish_table_launch_transition")

	home.call("_show_quick_play_setup")
	home.call("_select_quick_play_mode", "gem")
	home.call("_start_quick_play_from_setup")
	_require(not bool(home.get("_is_launching_table")), "Gem Match must not trigger launch transition")
	_require(PublicTableRegistryScript.list_public_tables().size() == 1, "Gem Match must not create a public table")

	home.queue_free()
	PublicTableRegistryScript.reset()
	print("Table launch transition smoke test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
