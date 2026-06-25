extends RefCounted
class_name TableLaunchContext

static var launch_mode := "quick_play"
static var table_id := "mock_table_001"
static var is_training := false

static func configure(mode: String = "quick_play", id: String = "mock_table_001") -> void:
	launch_mode = mode
	table_id = id
	is_training = mode == "training"

static func reset() -> void:
	configure()
