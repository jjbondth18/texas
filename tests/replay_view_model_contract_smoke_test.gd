extends SceneTree

const MockDataProvider := preload("res://scripts/demo/mock_data_provider.gd")

func _init() -> void:
	var replay := MockDataProvider.get_replay_view_model()
	_assert(Dictionary(replay).has("summary"), "summary missing")
	_assert(Array(replay.get("records", [])).size() > 0, "records missing")

	var selected := Dictionary(replay.get("selected_replay", {}))
	_assert(selected.has("equity_timeline"), "equity timeline missing")
	_assert(Array(selected.get("equity_timeline", [])).size() >= 4, "equity timeline incomplete")
	_assert(bool(selected.get("premium_required", false)), "premium lock flag missing")

	print("Replay view model contract smoke test passed.")
	quit(0)

func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
