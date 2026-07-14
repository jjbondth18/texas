extends SceneTree

const ProfileServiceScript := preload("res://scripts/services/profile_service.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
var _failures: Array[String] = []

func _init() -> void:
	ProfileServiceScript.reset_mock_profile()
	var service := ProfileServiceScript.new()
	var synced := service.apply_server_profile_snapshot({
		"player_id": "player_server_1",
		"display_name": "Game Display",
		"steam_persona_name": "Steam Persona",
		"steam_id": "76561198000000001",
		"display_name_updated_at": "2026-07-09T00:00:00.000Z",
		"is_new_player": true,
		"avatar_id": "default",
		"wallet": {"chips": 10000, "gems": 3},
		"progression": {"total_xp": 450, "level": 5, "title_id": "table_regular"},
		"statistics": {"hands_played": 12, "hands_won": 4, "chips_won": 2300, "gems_won": 2},
		"unlocked_avatar_ids": ["default"],
		"daily_bonus": {
			"claim_count": 5,
			"cycle_day": 6,
			"claimed_days_in_cycle": 5,
			"can_claim_today": true,
			"already_claimed_today": false,
			"claim_date": "2026-07-10",
		},
		"created_at": "2026-07-01T00:00:00.000Z",
		"updated_at": "2026-07-10T00:00:00.000Z",
	})
	_require(String(synced.get("player_id", "")) == "player_server_1", "server player_id should apply")
	_require(bool(synced.get("is_new_player", false)), "server is_new_player should apply")
	_require(PlayerProfileScript.get_player_name(synced) == "Game Display", "server display_name should apply")
	_require(String(synced.get("steam_persona_name", "")) == "Steam Persona", "Steam persona should be stored separately")
	_require(String(synced.get("steam_id", "")) == "76561198000000001", "SteamID should apply")
	_require(String(synced.get("display_name_updated_at", "")) == "2026-07-09T00:00:00.000Z", "rename timestamp should apply")
	_require(PlayerProfileScript.get_total_chips(synced) == 10000, "server chips should apply")
	_require(PlayerProfileScript.get_total_gems(synced) == 3, "server gems should apply")
	_require(int(synced.get("total_xp", -1)) == 450, "server XP should apply")
	_require(int(synced.get("level", -1)) == 5, "server level should apply")
	_require(String(synced.get("title_id", "")) == "table_regular", "server title should apply")
	_require(int(synced.get("total_hands_played", -1)) == 12, "server hands played should apply")
	_require(int(synced.get("total_hands_won", -1)) == 4, "server hands won should apply")
	_require(int(synced.get("chips_won", -1)) == 2300, "server chips won should apply")
	_require(int(synced.get("gems_won", -1)) == 2, "server gems won should apply")
	_require(int(synced.get("daily_bonus_claim_count", -1)) == 5, "server daily status should apply")
	_require(bool(synced.get("daily_bonus_can_claim_today", false)), "server daily claimability should apply")
	_require(String(synced.get("created_at", "")) == "2026-07-01T00:00:00.000Z", "created_at should apply")
	_require(String(synced.get("updated_at", "")) == "2026-07-10T00:00:00.000Z", "updated_at should apply")
	var repeated := service.apply_server_profile_snapshot({
		"player_id": "player_server_1",
		"display_name": "Game Display",
		"steam_persona_name": "Changed Steam Persona",
		"steam_id": "76561198000000001",
		"is_new_player": false,
		"avatar_id": "default",
		"wallet": {"chips": 10000, "gems": 3},
		"progression": {"total_xp": 450, "level": 5, "title_id": "table_regular"},
		"statistics": {"hands_played": 12, "hands_won": 4, "chips_won": 2300, "gems_won": 2},
		"unlocked_avatar_ids": ["default"],
		"daily_bonus": {
			"claim_count": 5,
			"cycle_day": 6,
			"claimed_days_in_cycle": 5,
			"can_claim_today": true,
			"already_claimed_today": false,
			"claim_date": "2026-07-10",
		},
		"created_at": "2026-07-01T00:00:00.000Z",
		"updated_at": "2026-07-10T00:00:00.000Z",
	})
	_require(PlayerProfileScript.get_total_chips(repeated) == 10000, "repeated snapshot should not add chips")
	_require(not bool(repeated.get("is_new_player", true)), "repeated snapshot should be able to clear is_new_player")
	_require(int(repeated.get("total_xp", -1)) == 450, "repeated snapshot should not add XP")
	_require(int(repeated.get("total_hands_played", -1)) == 12, "repeated snapshot should not add stats")
	_require(PlayerProfileScript.get_player_name(repeated) == "Game Display", "Steam persona refresh should not replace display name")
	_require(String(repeated.get("steam_persona_name", "")) == "Changed Steam Persona", "repeated snapshot should refresh Steam persona")
	ProfileServiceScript.reset_mock_profile()
	_finish("Server profile snapshot integration test passed.")

func _require(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish(success_message: String) -> void:
	if _failures.is_empty():
		print(success_message)
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
