extends RefCounted
class_name AppRoutes

const HOME := "home"
const PLAY := "play"
const REPLAY := "replay"
const STORE := "store"
const PROFILE := "profile"
const SETTINGS := "settings"

const QUICK_PLAY := "quick_play"
const ROOM_BROWSER := "room_browser"
const PRIVATE_TABLE := "private_table"
const TRAINING := "training"
const EVENTS := "events"

const REPLAY_DETAIL := "replay_detail"
const REPLAY_ANALYSIS := "replay_analysis"

const STORE_CHIPS := "store_chips"
const STORE_REPLAY_PRO := "store_replay_pro"
const STORE_COSMETICS := "store_cosmetics"
const STORE_MEMBERSHIP := "store_membership"

const PROFILE_STATS := "profile_stats"
const PROFILE_COSMETICS := "profile_cosmetics"
const PROFILE_ACHIEVEMENTS := "profile_achievements"

const SETTINGS_GRAPHICS := "settings_graphics"
const SETTINGS_AUDIO := "settings_audio"
const SETTINGS_CONTROLS := "settings_controls"
const SETTINGS_LANGUAGE := "settings_language"
const SETTINGS_MOTION := "settings_motion"

const TABLE := "table"
const EXIT := "exit"

# Deprecated product routes retained only for backward-compatible mock callers.
const CLUB := "club"
const TOURNAMENTS := "tournaments"
const CASH_TABLES := "cash_tables"
const CLUB_GAMES := "club_games"
const TOURNAMENT_BROWSER := "tournament_browser"

const MAIN_NAV_ROUTES := [
	HOME,
	PLAY,
	REPLAY,
	STORE,
	PROFILE,
	SETTINGS,
]

const PLAY_MODE_ROUTES := [
	QUICK_PLAY,
	ROOM_BROWSER,
	PRIVATE_TABLE,
	TRAINING,
	EVENTS,
]

const REPLAY_ROUTES := [
	REPLAY,
	REPLAY_DETAIL,
	REPLAY_ANALYSIS,
]

const STORE_ROUTES := [
	STORE,
	STORE_CHIPS,
	STORE_REPLAY_PRO,
	STORE_COSMETICS,
	STORE_MEMBERSHIP,
]

const PROFILE_ROUTES := [
	PROFILE,
	PROFILE_STATS,
	PROFILE_COSMETICS,
	PROFILE_ACHIEVEMENTS,
]

const SETTINGS_ROUTES := [
	SETTINGS,
	SETTINGS_GRAPHICS,
	SETTINGS_AUDIO,
	SETTINGS_CONTROLS,
	SETTINGS_LANGUAGE,
	SETTINGS_MOTION,
]

const SYSTEM_ROUTES := [
	EXIT,
]

const DEPRECATED_ROUTES := [
	CLUB,
	TOURNAMENTS,
	CASH_TABLES,
	CLUB_GAMES,
	TOURNAMENT_BROWSER,
]

static func all_routes() -> Array[String]:
	var routes: Array[String] = []
	routes.append_array(MAIN_NAV_ROUTES)
	routes.append_array(PLAY_MODE_ROUTES)
	routes.append_array(REPLAY_ROUTES)
	routes.append_array(STORE_ROUTES)
	routes.append_array(PROFILE_ROUTES)
	routes.append_array(SETTINGS_ROUTES)
	routes.append(TABLE)
	routes.append_array(SYSTEM_ROUTES)
	routes.append_array(DEPRECATED_ROUTES)
	return routes

static func is_known_route(route_id: String) -> bool:
	return all_routes().has(route_id)

static func is_main_nav_route(route_id: String) -> bool:
	return MAIN_NAV_ROUTES.has(route_id)

static func is_mode_route(route_id: String) -> bool:
	return PLAY_MODE_ROUTES.has(route_id)

static func is_play_mode_route(route_id: String) -> bool:
	return PLAY_MODE_ROUTES.has(route_id)

static func is_replay_route(route_id: String) -> bool:
	return REPLAY_ROUTES.has(route_id)

static func is_store_route(route_id: String) -> bool:
	return STORE_ROUTES.has(route_id)

static func is_profile_route(route_id: String) -> bool:
	return PROFILE_ROUTES.has(route_id)

static func is_settings_route(route_id: String) -> bool:
	return SETTINGS_ROUTES.has(route_id)

static func is_system_route(route_id: String) -> bool:
	return SYSTEM_ROUTES.has(route_id)
