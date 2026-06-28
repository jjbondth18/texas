extends SceneTree

const SaveManagerScript := preload("res://scripts/services/save_manager.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")

func _init() -> void:
	var migrated: Dictionary = SaveManagerScript.migrate_profile_save({
		"name": "LegacyPlayer",
		"chips": 12345,
		"avatar_id": "1_01",
	})

	_require(int(migrated.get("schema_version", 0)) == PlayerProfileScript.SCHEMA_VERSION, "migration must set current schema version")
	_require(PlayerProfileScript.get_total_chips(migrated) == 12345, "migration must preserve chips")
	_require(String(migrated.get("player_name", "")) == "LegacyPlayer", "migration must preserve name")
	_require(migrated.has("total_sessions_played"), "migration must add sessions field")
	_require(migrated.has("total_hands_played"), "migration must add hands field")
	_require(migrated.has("total_hands_won"), "migration must add hands won field")
	_require(migrated.has("total_profit"), "migration must add total profit field")
	_require(migrated.has("biggest_pot"), "migration must add biggest pot field")
	_require(migrated.has("best_session_profit"), "migration must add best session profit field")
	_require(migrated.has("best_hand_desc"), "migration must add best hand field")
	_require(PlayerProfileScript.get_total_gems(migrated) == 0, "migration must default missing gems to 0")
	_require(String(migrated.get("last_daily_reward_date", "")) == "", "migration must add daily reward date")
	_require(not bool(migrated.get("daily_reward_claimed_today", true)), "migration must default daily reward claimed to false")

	print("Save manager profile migration test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
