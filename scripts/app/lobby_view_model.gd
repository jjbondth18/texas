extends RefCounted
class_name LobbyViewModel

const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
const LobbyModeScript := preload("res://scripts/data/lobby_mode.gd")
const DailyBonusStateScript := preload("res://scripts/data/daily_bonus_state.gd")

var player
var main_nav: Array = []
var modes: Array = []
var daily_bonus

func _init(profile = null, lobby_modes: Array = [], bonus_state = null, nav_items: Array = []) -> void:
	player = profile if profile != null else PlayerProfileScript.new()
	main_nav = nav_items.duplicate()
	modes = lobby_modes.duplicate()
	daily_bonus = bonus_state if bonus_state != null else DailyBonusStateScript.new()

func to_dict() -> Dictionary:
	var mode_data: Array[Dictionary] = []
	for mode in modes:
		mode_data.append(mode.to_dict())
	return {
		"player": player.to_lobby_dict(),
		"main_nav": main_nav.duplicate(true),
		"modes": mode_data,
		"daily_bonus": daily_bonus.to_dict(),
	}

static func from_dict(data: Dictionary):
	var parsed_modes: Array = []
	for mode_data in Array(data.get("modes", [])):
		parsed_modes.append(LobbyModeScript.from_dict(mode_data))
	return load("res://scripts/app/lobby_view_model.gd").new(
		PlayerProfileScript.from_dict(Dictionary(data.get("player", {}))),
		parsed_modes,
		DailyBonusStateScript.from_dict(Dictionary(data.get("daily_bonus", {}))),
		Array(data.get("main_nav", []))
	)
