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

const TABLE := "table"
const EXIT := "exit"

# Deprecated compatibility routes. Do not use these as main Home Lobby nav items.
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

const MODE_ROUTES := [
	QUICK_PLAY,
	PRIVATE_TABLE,
	ROOM_BROWSER,
	TRAINING,
	EVENTS,
]

const SYSTEM_ROUTES := [
	SETTINGS,
	EXIT,
]

const DEPRECATED_ROUTES := [
	CLUB,
	TOURNAMENTS,
	CASH_TABLES,
	CLUB_GAMES,
	TOURNAMENT_BROWSER,
	TABLE,
]

static func all_routes() -> Array[String]:
	var routes: Array[String] = []
	routes.append_array(MAIN_NAV_ROUTES)
	routes.append_array(MODE_ROUTES)
	routes.append_array(SYSTEM_ROUTES)
	routes.append_array(DEPRECATED_ROUTES)
	return routes

static func is_known_route(route_id: String) -> bool:
	return all_routes().has(route_id)

static func is_main_nav_route(route_id: String) -> bool:
	return MAIN_NAV_ROUTES.has(route_id)

static func is_mode_route(route_id: String) -> bool:
	return MODE_ROUTES.has(route_id)

static func is_system_route(route_id: String) -> bool:
	return SYSTEM_ROUTES.has(route_id)
