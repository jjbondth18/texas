extends RefCounted
class_name MockDataProvider

const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
const LobbyModeScript := preload("res://scripts/data/lobby_mode.gd")
const DailyBonusStateScript := preload("res://scripts/data/daily_bonus_state.gd")
const RoomInfoScript := preload("res://scripts/data/room_info.gd")
const TableStateScript := preload("res://scripts/data/table_state.gd")
const LobbyViewModelScript := preload("res://scripts/app/lobby_view_model.gd")
const RoomBrowserViewModelScript := preload("res://scripts/app/room_browser_view_model.gd")
const TableViewModelScript := preload("res://scripts/app/table_view_model.gd")
const ReplayViewModelScript := preload("res://scripts/app/replay_view_model.gd")
const StoreViewModelScript := preload("res://scripts/app/store_view_model.gd")
const ProfileViewModelScript := preload("res://scripts/app/profile_view_model.gd")
const SettingsViewModelScript := preload("res://scripts/app/settings_view_model.gd")

const LOCAL_AVATAR_ID := "4_05"
const LOCAL_AVATAR_PATH := "res://assets/playersAv_cut/%s.png" % LOCAL_AVATAR_ID

static func get_mock_player_profile() -> Dictionary:
	return _mock_player_profile().to_lobby_dict()

static func get_lobby_view_model() -> Dictionary:
	return LobbyViewModelScript.new(
		_mock_player_profile(),
		_mock_lobby_modes(),
		_mock_daily_bonus(),
		_mock_main_nav_items()
	).to_dict()

static func get_mock_rooms() -> Array[Dictionary]:
	var rooms: Array[Dictionary] = []
	for room in _mock_room_infos():
		rooms.append(room.to_dict())
	return rooms

static func get_room_browser_view_model() -> Dictionary:
	return RoomBrowserViewModelScript.new(_mock_room_infos()).to_dict()

static func get_table_view_model() -> Dictionary:
	var table := TableStateScript.new("mock_table_001", "Neon Table 01")
	table.blinds_text = "25 / 50"
	table.pot = 400
	table.phase = "preflop"
	table.community_cards = []
	table.seats = []
	table.local_player = {}
	table.available_actions = []
	return TableViewModelScript.new(table).to_dict()

static func get_replay_view_model() -> Dictionary:
	return ReplayViewModelScript.new().to_dict()

static func get_store_view_model() -> Dictionary:
	return StoreViewModelScript.new().to_dict()

static func get_profile_view_model() -> Dictionary:
	return ProfileViewModelScript.new().to_dict()

static func get_settings_view_model() -> Dictionary:
	return SettingsViewModelScript.new().to_dict()

static func _mock_player_profile():
	return PlayerProfileScript.new(
		"Luna0581",
		24,
		875,
		1500,
		24500,
		1250,
		LOCAL_AVATAR_PATH,
		PlayerProfileScript.DEFAULT_PLAYER_ID,
		LOCAL_AVATAR_ID,
		LOCAL_AVATAR_ID,
		[LOCAL_AVATAR_ID]
	)

static func _mock_lobby_modes() -> Array:
	return [
		LobbyModeScript.new("quick_play", "QUICK PLAY", "Jump into a table instantly", "res://assets/home_lobby/mode_cards/mode_quick_play.png", true, "quick_play"),
		LobbyModeScript.new("room_browser", "ROOM BROWSER", "Choose a table from the lobby", "res://assets/home_lobby/mode_cards/mode_cash_tables.png", true, "room_browser"),
		LobbyModeScript.new("private_table", "FRIENDS ROOM", "Create a local room with friends", "res://assets/home_lobby/mode_cards/mode_private_table.png", true, "private_table"),
		LobbyModeScript.new("training", "TRAINING", "Practice against AI and learn safely", "res://assets/home_lobby/mode_cards/mode_tournaments.png", true, "training"),
		LobbyModeScript.new("events", "EVENTS", "Limited-time tables and special rules", "res://assets/home_lobby/mode_cards/mode_club_games.png", true, "events"),
	]

static func _mock_main_nav_items() -> Array[Dictionary]:
	return [
		{"id": "home", "label": "HOME", "route": "home"},
		{"id": "play", "label": "PLAY", "route": "play"},
		{"id": "replay", "label": "REPLAY", "route": "replay"},
		{"id": "store", "label": "STORE", "route": "store"},
		{"id": "profile", "label": "PROFILE", "route": "profile"},
		{"id": "settings", "label": "SETTINGS", "route": "settings"},
	]

static func _mock_daily_bonus():
	return DailyBonusStateScript.new(4, [
		{"day": 1, "reward": 500, "claimed": true},
		{"day": 2, "reward": 750, "claimed": true},
		{"day": 3, "reward": 1000, "claimed": true},
		{"day": 4, "reward": 1500, "claimed": false},
		{"day": 5, "reward": 2000, "claimed": false},
		{"day": 6, "reward": 3000, "claimed": false},
		{"day": 7, "reward": 5000, "claimed": false},
	])

static func _mock_room_infos() -> Array:
	return [
		RoomInfoScript.new("mock_room_001", "Neon Table 01", "cash_tables", 4, 6, 25, 50, 1000, 10000, "open", false),
		RoomInfoScript.new("mock_room_002", "Velvet Room 02", "cash_tables", 2, 6, 50, 100, 2500, 20000, "open", false),
		RoomInfoScript.new("mock_room_003", "Private Lounge", "private_table", 1, 6, 10, 20, 500, 5000, "locked", true),
	]
