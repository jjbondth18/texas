extends SceneTree

const PokerTableScene := preload("res://scenes/screens/poker_table_screen.tscn")
const TableLaunchContext := preload("res://scripts/app/table_launch_context.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_args()
	if OS.has_method("get_cmdline_user_args"):
		args.append_array(OS.get_cmdline_user_args())
	var phase := "preflop"
	var launch_mode := "quick_play"
	var output := "res://docs/screenshots/runtime_poker_table_preflop.png"
	var phase_index := args.find("--capture-table-phase")
	if phase_index >= 0 and phase_index + 1 < args.size():
		phase = String(args[phase_index + 1])
	var output_index := args.find("--capture-output")
	if output_index >= 0 and output_index + 1 < args.size():
		output = String(args[output_index + 1])
	var mode_index := args.find("--launch-mode")
	if mode_index >= 0 and mode_index + 1 < args.size():
		launch_mode = String(args[mode_index + 1])
	TableLaunchContext.configure(launch_mode, "mock_training_table_001" if launch_mode == "training" else "mock_table_001")

	root.size = Vector2i(1920, 1080)
	var scene = PokerTableScene.instantiate()
	root.add_child(scene)
	await process_frame
	if scene.has_method("_load_phase"):
		scene._load_phase(phase)
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	var error := image.save_png(output)
	if error != OK:
		push_error("Failed to save poker table capture: %s" % output)
		quit(1)
		return
	print("Poker table runtime capture saved: %s" % output)
	quit(0)
